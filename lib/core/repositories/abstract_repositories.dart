import '../models/user.dart';
import '../models/service.dart';
import '../models/job.dart';
import '../models/transaction.dart';
import '../models/message.dart';
import '../models/order.dart';
import '../models/job_application.dart';
import '../models/withdrawal_request.dart';
import '../models/dispute.dart';

/// Abstract repository for user operations
abstract class UserRepository {
  /// Get current user profile
  Future<User> getCurrentUserProfile();

  /// Update user profile
  Future<void> updateUserProfile({required Map<String, dynamic> data});

  /// Upload user avatar
  Future<String> uploadAvatar({required List<int> bytes});

  /// Get user by ID
  Future<User> getUserById({required String userId});

  /// Search users
  Future<List<User>> searchUsers({
    required String query,
    String? category,
  });

  /// Get user reviews
  Future<List<Map<String, dynamic>>> getUserReviews({required String userId});

  /// Get users by type (e.g., job_seeker)
  Future<List<User>> getUsers({String? userType, int? limit});

  /// Upload a verification document
  Future<String> uploadVerificationDoc({required List<int> bytes, required String fileName});

  /// Submit verification request with documents
  Future<void> submitVerification({
    required String idType,
    required String idFrontUrl,
    String? idBackUrl,
    String? selfieUrl,
  });

  /// Report a user for misconduct or scam
  Future<void> reportUser({
    required String targetUserId,
    required String reason,
    String? description,
  });

  /// Block a user
  Future<void> blockUser({required String targetUserId});

  /// Ensure user profile exists in public.users table
  Future<void> ensureProfileExists();
  }

  /// Abstract repository for services

abstract class ServiceRepository {
  /// Create a new service
  Future<Service> createService({
    required Map<String, dynamic> data,
  });

  /// Upload service image
  Future<String> uploadServiceImage({required List<int> bytes});

  /// Get all services
  Future<List<Service>> getServices({
    String? category,
    String? sortBy,
  });

  /// Get service by ID
  Future<Service> getServiceById({required String serviceId});

  /// Update service
  Future<void> updateService({
    required String serviceId,
    required Map<String, dynamic> data,
  });

  /// Delete service
  Future<void> deleteService({required String serviceId});

  /// Search services
  Future<List<Service>> searchServices({
    required String query,
    String? category,
    String? location,
  });

  /// Get user's own services
  Future<List<Service>> getMyServices();
}

/// Abstract repository for job operations
abstract class JobRepository {
  /// Create a new job
  Future<Job> createJob({required Map<String, dynamic> data});

  /// Upload job image
  Future<String> uploadJobImage({required List<int> bytes});

  /// Get all jobs
  Future<List<Job>> getJobs({String? status, String? category});

  /// Get job by ID
  Future<Job> getJobById({required String jobId});

  /// Update job
  Future<void> updateJob({
    required String jobId,
    required Map<String, dynamic> data,
  });

  /// Delete job
  Future<void> deleteJob({required String jobId});

  /// Search jobs
  Future<List<Job>> searchJobs({
    required String query,
    String? category,
    String? location,
  });

  /// Get jobs posted by the current user
  Future<List<Job>> getMyJobs();

  /// Apply for a job
  Future<JobApplication> applyForJob({
    required String jobId,
    String? coverLetter,
    double? bidAmount,
  });

  /// Get applications for a specific job (for client)
  Future<List<JobApplication>> getJobApplications({required String jobId});

  /// Get my job applications (for applicant)
  Future<List<JobApplication>> getMyApplications();

  /// Update application status (for client to accept/reject)
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  });
}

/// Abstract repository for order operations
abstract class OrderRepository {
  /// Create a new order
  Future<Order> createOrder({
    required String serviceId,
    required String sellerId,
    required double amount,
  });

  /// Get order by ID
  Future<Order> getOrderById({required String orderId});

  /// Get orders where user is buyer
  Future<List<Order>> getMyPurchases();

  /// Get orders where user is seller
  Future<List<Order>> getMySales();

  /// Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });

  /// Raise a dispute for an order
  Future<void> raiseDispute({
    required String orderId,
    required String reason,
    required String description,
  });
}

/// Abstract repository for transaction operations
abstract class TransactionRepository {
  /// Get transaction history
  Future<List<Transaction>> getTransactionHistory();

  /// Get wallet balance
  Future<double> getWalletBalance();

  /// Get escrow balance
  Future<double> getEscrowBalance();

  /// Get total earned amount
  Future<double> getTotalEarned();

  /// Deposit funds into wallet
  Future<Transaction> depositFunds({
    required double amount,
    required String reference,
    required String gateway, // Ozow, PayFast, etc.
  });

  /// Request withdrawal
  Future<void> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String branchCode,
    required String accountType,
  });

  /// Create escrow payment
  Future<Transaction> createEscrowPayment({
    required double amount,
    required String receiverId,
    required String orderId,
  });

  /// Release escrow to seller
  Future<void> releaseEscrow({required String orderId});

  /// Refund escrow to buyer
  Future<void> refundEscrow({required String orderId});

  /// Get my withdrawal requests
  Future<List<WithdrawalRequest>> getMyWithdrawalRequests();

  /// Process direct payment (if needed)
  Future<Transaction> processPayment({
    required double amount,
    required String receiverId,
    required String serviceId,
  });
}

/// Abstract repository for dispute operations
abstract class DisputeRepository {
  /// Get dispute by order ID
  Future<Dispute?> getDisputeByOrderId({required String orderId});

  /// Get my raised disputes
  Future<List<Dispute>> getMyDisputes();

  /// Cancel a dispute
  Future<void> cancelDispute({required String disputeId});
}

/// Abstract repository for message operations
abstract class MessageRepository {
  /// Send a message
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
    String? imageUrl,
  });

  /// Upload chat image
  Future<String> uploadChatImage({required List<int> bytes});

  /// Get messages between two users
  Future<List<Message>> getChatMessages({required String otherUserId});

  /// Get all chat conversations for current user
  Future<List<Map<String, dynamic>>> getConversations();

  /// Mark messages as read
  Future<void> markAsRead({required String senderId});

  /// Stream of new messages for a conversation
  Stream<List<Message>> watchMessages({required String otherUserId});

  /// Stream of all conversations
  Stream<List<Map<String, dynamic>>> watchConversations();
}

/// Abstract repository for review operations
abstract class ReviewRepository {
  /// Create review
  Future<Map<String, dynamic>> createReview({
    required String targetUserId,
    required int rating,
    required String comment,
    String? serviceId,
  });

  /// Get reviews for user
  Future<List<Map<String, dynamic>>> getUserReviews({required String userId});

  /// Update review
  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  });

  /// Delete review
  Future<void> deleteReview({required String reviewId});
}
