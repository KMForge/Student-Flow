import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Task Provider
/// Manages task state and operations using Provider pattern
class TaskProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter states
  String _statusFilter = 'All'; // 'All', 'Pending', 'Completed'
  String? _subjectFilter;
  
  // Periodic notification rescheduling
  Timer? _notificationRescheduleTimer;
  String? _currentUserId;

  List<Task> get tasks => _tasks;
  List<Task> get filteredTasks => _filteredTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;
  String? get subjectFilter => _subjectFilter;

  /// Get task statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.status == 'Completed').length;
  int get pendingTasks => _tasks.where((t) => t.status == 'Pending').length;
  
  /// Get tasks due today
  List<Task> get tasksDueToday {
    final today = DateTime.now();
    return _tasks.where((task) {
      final taskDate = task.deadline;
      return taskDate.year == today.year &&
          taskDate.month == today.month &&
          taskDate.day == today.day;
    }).toList();
  }
  
  /// Get upcoming deadlines (within 3 days)
  int get upcomingDeadlines {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));
    return _tasks.where((task) {
      return task.status == 'Pending' &&
          task.deadline.isAfter(now) &&
          task.deadline.isBefore(threeDaysLater);
    }).length;
  }

  /// Load all tasks for a user
  Future<void> loadTasks(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentUserId = userId;
    notifyListeners();

    try {
      _tasks = await _databaseService.getAllTasks(userId);
      _applyFilters();
      
      // Reschedule notifications for all pending tasks with future deadlines
      await _rescheduleNotifications();
      
      // Start periodic notification rescheduling (every 5 minutes)
      _startPeriodicNotificationRescheduling();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Start periodic notification rescheduling
  /// This ensures notifications are always up-to-date, even if the app is idle
  void _startPeriodicNotificationRescheduling() {
    // Cancel existing timer if any
    _notificationRescheduleTimer?.cancel();
    
    // Schedule periodic rescheduling every 5 minutes
    _notificationRescheduleTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        if (_currentUserId != null && _tasks.isNotEmpty) {
          debugPrint('🔄 Periodic notification rescheduling triggered');
          await _rescheduleNotifications();
        }
      },
    );
    
    debugPrint('✅ Started periodic notification rescheduling (every 5 minutes)');
  }
  
  /// Stop periodic notification rescheduling
  void _stopPeriodicNotificationRescheduling() {
    _notificationRescheduleTimer?.cancel();
    _notificationRescheduleTimer = null;
    debugPrint('🛑 Stopped periodic notification rescheduling');
  }
  
  /// Public method to manually reschedule notifications
  /// Can be called when app comes to foreground or when needed
  Future<void> rescheduleNotifications() async {
    if (_currentUserId != null) {
      await _rescheduleNotifications();
    }
  }

  /// Reschedule notifications for all pending tasks
  /// This ensures notifications work from anywhere (dashboard, home, etc.)
  /// Called automatically when tasks are loaded and periodically every 5 minutes
  Future<void> _rescheduleNotifications() async {
    final now = DateTime.now();
    final notificationService = NotificationService();
    
    // Only reschedule if notifications are enabled
    if (!await notificationService.areNotificationsEnabled()) {
      debugPrint('🔔 Notifications are disabled, skipping reschedule');
      return;
    }
    
    final pendingTasks = _tasks.where((task) => 
      task.status == 'Pending' && 
      task.deadline.isAfter(now) && 
      task.id != null
    ).toList();
    
    debugPrint('🔔 Rescheduling notifications for ${pendingTasks.length} pending task(s)');
    debugPrint('   Current time: ${now.toString()}');
    
    for (final task in pendingTasks) {
      try {
        // Calculate time until deadline
        final timeUntilDeadline = task.deadline.difference(now);
        final oneHourBefore = task.deadline.subtract(const Duration(hours: 1));
        final thirtyMinutesBefore = task.deadline.subtract(const Duration(minutes: 30));
        
        debugPrint('   Task: "${task.title}"');
        debugPrint('     Deadline: ${task.deadline.toString()}');
        debugPrint('     Time until deadline: ${timeUntilDeadline.inMinutes} minutes');
        debugPrint('     1-hour notification time: ${oneHourBefore.toString()}');
        debugPrint('     30-minute notification time: ${thirtyMinutesBefore.toString()}');
        
        // Cancel existing notifications first to avoid duplicates
        await notificationService.cancelTaskNotifications(task.id!);
        
        // Schedule new notifications (1 hour and 30 minutes before deadline)
        // This will handle all edge cases including:
        // - If 1 hour before is in the past, it will schedule for 2 minutes from now
        // - If 1 hour before is very close, it will show immediately
        // - If deadline is less than 1 hour away, it will skip 1-hour notification
        await notificationService.scheduleTaskNotifications(
          taskId: task.id!,
          taskTitle: task.title,
          deadline: task.deadline,
        );
        debugPrint('     ✅ Scheduled notifications for task: "${task.title}"');
      } catch (e) {
        debugPrint('     ❌ Failed to schedule notifications for task "${task.title}": $e');
      }
    }
    
    debugPrint('✅ Finished rescheduling notifications for all tasks');
  }
  
  /// Dispose resources
  void dispose() {
    _stopPeriodicNotificationRescheduling();
    super.dispose();
  }

  /// Create new task
  Future<bool> createTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Insert task (notifications will be scheduled automatically in loadTasks)
      await _databaseService.insertTask(task);
      await loadTasks(task.userId);
      
      // Note: Notifications are already scheduled in _rescheduleNotifications()
      // which is called by loadTasks(), so we don't need to schedule again here
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing task
  Future<bool> updateTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate task has an ID
      if (task.id == null) {
        _errorMessage = 'Task ID is required for update';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Get old task to check if deadline changed
      final oldTask = await _databaseService.getTaskById(task.id!);
      if (oldTask == null) {
        _errorMessage = 'Task not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Cancel old notifications before updating
      await NotificationService().cancelTaskNotifications(task.id!);
      
      // Update task in database
      final updateResult = await _databaseService.updateTask(task);
      if (updateResult == 0) {
        _errorMessage = 'Failed to update task';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Reload tasks (this will automatically reschedule notifications via _rescheduleNotifications)
      await loadTasks(task.userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating task: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error in updateTask: $e');
      return false;
    }
  }

  /// Delete task
  Future<bool> deleteTask(int taskId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cancel notifications before deleting
      await NotificationService().cancelTaskNotifications(taskId);
      
      await _databaseService.deleteTask(taskId);
      await loadTasks(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle task completion status
  Future<bool> toggleTaskStatus(int taskId, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final task = await _databaseService.getTaskById(taskId);
      if (task != null) {
        final newStatus = task.status == 'Completed' ? 'Pending' : 'Completed';
        final updatedTask = task.copyWith(status: newStatus);
        await _databaseService.updateTask(updatedTask);
        
        // Cancel notifications if task is completed
        if (newStatus == 'Completed') {
          await NotificationService().cancelTaskNotifications(taskId);
        } else {
          // Schedule notifications if task is back to pending and deadline is in the future
          if (updatedTask.deadline.isAfter(DateTime.now())) {
            await NotificationService().scheduleTaskNotifications(
              taskId: taskId,
              taskTitle: updatedTask.title,
              deadline: updatedTask.deadline,
            );
          }
        }
        
        await loadTasks(userId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set status filter
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  /// Set subject filter
  void setSubjectFilter(String? subject) {
    _subjectFilter = subject;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _statusFilter = 'All';
    _subjectFilter = null;
    _applyFilters();
    notifyListeners();
  }

  /// Apply filters to tasks
  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      // Status filter
      if (_statusFilter != 'All' && task.status != _statusFilter) {
        return false;
      }

      // Subject filter
      if (_subjectFilter != null && task.subject != _subjectFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Get unique subjects
  Future<List<String>> getSubjects(String userId) async {
    try {
      return await _databaseService.getSubjects(userId);
    } catch (e) {
      return [];
    }
  }

  /// Get analytics data (completion percentage per subject)
  Map<String, double> getAnalytics(String userId) {
    final Map<String, List<Task>> tasksBySubject = {};

    for (var task in _tasks) {
      if (!tasksBySubject.containsKey(task.subject)) {
        tasksBySubject[task.subject] = [];
      }
      tasksBySubject[task.subject]!.add(task);
    }

    final Map<String, double> analytics = {};
    tasksBySubject.forEach((subject, subjectTasks) {
      final completed = subjectTasks
          .where((t) => t.status == 'Completed')
          .length;
      final percentage = subjectTasks.isEmpty
          ? 0.0
          : (completed / subjectTasks.length) * 100;
      analytics[subject] = percentage;
    });

    return analytics;
  }
}
