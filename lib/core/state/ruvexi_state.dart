import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../network/api_config.dart';
import '../network/ruvexi_api_client.dart';

class ServiceItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final int durationMinutes;
  final int bufferMinutes;
  final String description;
  final bool popular;
  final bool isOnlineBookable;
  final bool isActive;

  ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
    this.bufferMinutes = 5,
    this.description = '',
    this.popular = false,
    this.isOnlineBookable = true,
    this.isActive = true,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Service').toString(),
      category: (json['category'] ?? 'Hair').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse('${json['price']}') ?? 0.0,
      durationMinutes: (json['durationMinutes'] is num)
          ? (json['durationMinutes'] as num).toInt()
          : int.tryParse('${json['durationMinutes']}') ?? 45,
      bufferMinutes: (json['bufferMinutes'] is num) ? (json['bufferMinutes'] as num).toInt() : 5,
      description: (json['description'] ?? '').toString(),
      popular: json['popular'] == true,
      isOnlineBookable: json['isOnlineBookable'] != false,
      isActive: json['isActive'] != false,
    );
  }
}

class PackageItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final List<String> servicesIncluded;

  PackageItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.servicesIncluded,
  });
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String gender;
  final String dateOfBirth;
  final int visitsCount;
  final double totalSpent;
  final int loyaltyPoints;
  final String membership;
  final String? formulaNotes;
  final String tag; // "Regular", "New", "Inactive"
  final String branchId;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.gender = "Female",
    this.dateOfBirth = "",
    required this.visitsCount,
    required this.totalSpent,
    this.loyaltyPoints = 50,
    this.membership = "Standard",
    this.formulaNotes,
    this.tag = "Regular",
    this.branchId = "",
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final visits = (json['visitsCount'] ?? json['totalVisits'] ?? 0);
    final spent = (json['totalSpent'] ?? json['totalSpend'] ?? 0.0);
    final visitsInt = visits is num ? visits.toInt() : int.tryParse('$visits') ?? 0;
    final tagsRaw = json['tags'];
    String derivedTag = visitsInt <= 1 ? 'New' : 'Regular';
    if (tagsRaw is List && tagsRaw.isNotEmpty) {
      derivedTag = tagsRaw.first.toString();
    }
    return Customer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Guest').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      gender: (json['gender'] ?? 'Female').toString(),
      dateOfBirth: (json['birthday'] ?? json['dateOfBirth'] ?? json['dob'] ?? '').toString(),
      visitsCount: visitsInt,
      totalSpent: spent is num ? spent.toDouble() : double.tryParse('$spent') ?? 0.0,
      loyaltyPoints: (json['loyaltyPoints'] is num)
          ? (json['loyaltyPoints'] as num).toInt()
          : int.tryParse('${json['loyaltyPoints']}') ?? 50,
      membership: (json['vipTier'] ?? json['membership'] ?? 'Standard').toString(),
      formulaNotes: (json['formulaNotes'] ?? json['notes'])?.toString(),
      tag: derivedTag,
      branchId: (json['branchId'] ?? json['branch_id'] ?? '').toString(),
    );
  }

  bool get hasActiveMembership {
    final m = membership.toLowerCase();
    return m.contains("gold") ||
        m.contains("silver") ||
        m.contains("platinum") ||
        m.contains("diamond") ||
        m.contains("vip") ||
        m.contains("prime") ||
        m.contains("elite") ||
        (m.contains("member") && !m.contains("standard"));
  }

  double get membershipDiscountPercent {
    final m = membership.toLowerCase();
    if (m.contains("diamond") || m.contains("vip")) return 20.0;
    if (m.contains("platinum")) return 15.0;
    if (m.contains("gold")) return 10.0;
    if (m.contains("silver")) return 5.0;
    if (m.contains("prime") || m.contains("elite") || m.contains("member")) return 10.0;
    return 0.0;
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? gender,
    String? dateOfBirth,
    int? visitsCount,
    double? totalSpent,
    int? loyaltyPoints,
    String? membership,
    String? formulaNotes,
    String? tag,
    String? branchId,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      visitsCount: visitsCount ?? this.visitsCount,
      totalSpent: totalSpent ?? this.totalSpent,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      membership: membership ?? this.membership,
      formulaNotes: formulaNotes ?? this.formulaNotes,
      tag: tag ?? this.tag,
      branchId: branchId ?? this.branchId,
    );
  }
}

class Appointment {
  final String id;
  final String customerName;
  final String customerPhone;
  final String serviceName;
  final String staffName;
  final DateTime time;
  final int durationMinutes;
  final double price;
  String status; // "In Service", "Confirmed", "Upcoming", "Completed", "Cancelled"
  final String notes;
  final String branchId;

  Appointment({
    required this.id,
    required this.customerName,
    this.customerPhone = "",
    required this.serviceName,
    required this.staffName,
    required this.time,
    this.durationMinutes = 45,
    required this.price,
    required this.status,
    this.notes = "",
    this.branchId = "",
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final dateStr = (json['date'] ?? '').toString().trim();
    final timeStr = (json['startTime'] ?? json['time'] ?? '11:00').toString().trim();
    DateTime parsedTime = DateTime.now();
    try {
      final baseDate = dateStr.isNotEmpty ? DateTime.parse(dateStr) : DateTime.now();
      final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?', caseSensitive: false).firstMatch(timeStr);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final ampm = match.group(3)?.toUpperCase();
        if (ampm == 'PM' && h < 12) h += 12;
        if (ampm == 'AM' && h == 12) h = 0;
        parsedTime = DateTime(baseDate.year, baseDate.month, baseDate.day, h.clamp(0, 23), m.clamp(0, 59));
      } else {
        parsedTime = baseDate;
      }
    } catch (_) {
      parsedTime = DateTime.now();
    }

    final rawStatus = (json['status'] ?? 'confirmed').toString().toLowerCase().trim();
    String uiStatus = 'Confirmed';
    if (rawStatus == 'in_service' || rawStatus == 'in service') {
      uiStatus = 'In Service';
    } else if (rawStatus == 'completed') {
      uiStatus = 'Completed';
    } else if (rawStatus == 'cancelled') {
      uiStatus = 'Cancelled';
    } else if (rawStatus == 'upcoming' || rawStatus == 'pending' || rawStatus == 'scheduled') {
      uiStatus = 'Upcoming';
    }

    return Appointment(
      id: (json['id'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Guest').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? 'Salon Service').toString(),
      staffName: (json['staffName'] ?? 'Stylist').toString(),
      time: parsedTime,
      durationMinutes: (json['durationMinutes'] is num)
          ? (json['durationMinutes'] as num).toInt()
          : int.tryParse('${json['durationMinutes']}') ?? 45,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse('${json['price']}') ?? 0.0,
      status: uiStatus,
      notes: (json['notes'] ?? '').toString(),
      branchId: (json['branchId'] ?? json['branch_id'] ?? '').toString(),
    );
  }
}

class StaffMember {
  final String id;
  final String name;
  final String role;
  final String phone;
  bool isActive;
  bool isClockedIn;
  String checkInTime;
  int servicesCount;
  double serviceRevenue;
  double commissionRate;
  double rating;
  int assignedServicesCount;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    this.phone = "",
    this.isActive = true,
    this.isClockedIn = true,
    this.checkInTime = "--",
    this.servicesCount = 0,
    this.serviceRevenue = 0.0,
    this.commissionRate = 0.10,
    this.rating = 4.8,
    this.assignedServicesCount = 0,
  });

  String get staffName => name;
  double get todaySales => serviceRevenue;

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final rawRate = (json['commissionRate'] is num)
        ? (json['commissionRate'] as num).toDouble()
        : double.tryParse('${json['commissionRate']}') ?? 10.0;
    final normalizedRate = rawRate > 1.0 ? rawRate / 100.0 : rawRate;
    final clockedIn = json['isClockedIn'] == true;
    final clockedAt = (json['clockedInAt'] ?? '').toString();

    return StaffMember(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Staff').toString(),
      role: (json['role'] ?? 'Stylist').toString(),
      phone: (json['phone'] ?? '').toString(),
      isActive: json['isActive'] != false,
      isClockedIn: clockedIn,
      checkInTime: clockedAt.isNotEmpty ? clockedAt : (clockedIn ? 'Clocked In' : '--'),
      servicesCount: (json['totalServicesCompleted'] ?? json['todayServicesCount'] ?? 0) is num
          ? ((json['totalServicesCompleted'] ?? json['todayServicesCount']) as num).toInt()
          : 0,
      serviceRevenue: (json['todayRevenue'] is num)
          ? (json['todayRevenue'] as num).toDouble()
          : double.tryParse('${json['todayRevenue']}') ?? 0.0,
      commissionRate: normalizedRate,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.8,
      assignedServicesCount: (json['todayServicesCount'] is num)
          ? (json['todayServicesCount'] as num).toInt()
          : 0,
    );
  }
}

class InventoryItem {
  final String id;
  final String name;
  final String sizeVolume;
  final String category;
  int stock;
  final int minAlert;
  final String unit;
  final double price;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sizeVolume,
    required this.category,
    required this.stock,
    required this.minAlert,
    this.unit = "pcs",
    this.price = 0.0,
  });

  bool get isLowStock => stock <= minAlert;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final priceVal = json['retailPrice'] ?? json['sellingPrice'] ?? json['price'] ?? 0.0;
    return InventoryItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Product').toString(),
      sizeVolume: (json['brand'] ?? json['usageType'] ?? 'Professional').toString(),
      category: (json['category'] ?? 'Hair Care').toString(),
      stock: (json['currentStock'] is num)
          ? (json['currentStock'] as num).toInt()
          : int.tryParse('${json['currentStock']}') ?? 0,
      minAlert: (json['minThreshold'] is num)
          ? (json['minThreshold'] as num).toInt()
          : int.tryParse('${json['minThreshold']}') ?? 5,
      unit: (json['unit'] ?? 'pcs').toString(),
      price: priceVal is num ? priceVal.toDouble() : double.tryParse('$priceVal') ?? 0.0,
    );
  }
}

class ExpenseItem {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String branchId;

  ExpenseItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.note = "",
    this.branchId = "",
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    try {
      final raw = (json['date'] ?? '').toString();
      if (raw.isNotEmpty) parsedDate = DateTime.parse(raw);
    } catch (_) {}
    final title = (json['title'] ?? '').toString();
    final notes = (json['notes'] ?? '').toString();
    return ExpenseItem(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? 'Supplies').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse('${json['amount']}') ?? 0.0,
      date: parsedDate,
      note: notes.isNotEmpty ? notes : title,
      branchId: (json['branchId'] ?? json['branch_id'] ?? '').toString(),
    );
  }
}

class OfferItem {
  final String id;
  final String title;
  final String description;
  final String validity;
  bool isActive;
  final double discountPercent;

  OfferItem({
    required this.id,
    required this.title,
    required this.description,
    required this.validity,
    this.isActive = true,
    this.discountPercent = 20,
  });
}

class CartItem {
  final ServiceItem? _service;
  final InventoryItem? product;
  final String? customName;
  final double? customPrice;
  final String type; // 'service' or 'product'
  String? staffName; // Assigned Stylist
  int quantity;

  CartItem({
    ServiceItem? service,
    this.product,
    this.customName,
    this.customPrice,
    String? type,
    this.staffName,
    this.quantity = 1,
  })  : _service = service,
        type = type ?? (product != null ? 'product' : 'service');

  ServiceItem get service =>
      _service ??
      ServiceItem(
        id: product?.id ?? '',
        name: name,
        category: category,
        price: price,
        durationMinutes: 15,
      );

  bool get isProduct => type == 'product' || product != null;
  String get name => _service?.name ?? product?.name ?? customName ?? 'Item';
  double get price => _service?.price ?? product?.price ?? customPrice ?? 0.0;
  String get category => _service?.category ?? product?.category ?? 'General';
  String get id => _service?.id ?? product?.id ?? '';
}

class SalonSeat {
  final String id; // e.g., "S-1"
  bool isInUse;
  String? currentClientId;
  String? currentClientName;

  SalonSeat({
    required this.id,
    this.isInUse = false,
    this.currentClientId,
    this.currentClientName,
  });
}

class InSalonClient {
  final String id;
  final String customerName;
  final String phone;
  List<ServiceItem> services;
  String assignedStaff;
  String seatId; // e.g., "S-1" or "Waiting"
  final String checkInTime;
  int elapsedMinutes;
  String status; // "In Salon", "Waiting", "Completed"
  String notes;

  InSalonClient({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.services,
    required this.assignedStaff,
    required this.seatId,
    required this.checkInTime,
    this.elapsedMinutes = 5,
    this.status = "In Salon",
    this.notes = "",
  });

  String get servicesSummary => services.map((s) => s.name).join(" + ");
  double get totalServiceAmount => services.fold(0.0, (sum, s) => sum + s.price);
}

class SalonBranch {
  final String id;
  final String name;
  final String code;
  final String address;
  final String city;
  final String phone;
  final String email;
  final int chairs;
  final bool isActive;
  final String upiId;
  final String upiPayeeName;

  SalonBranch({
    required this.id,
    required this.name,
    this.code = "",
    this.address = "",
    this.city = "",
    this.phone = "",
    this.email = "",
    this.chairs = 6,
    this.isActive = true,
    this.upiId = "",
    this.upiPayeeName = "",
  });

  factory SalonBranch.fromJson(Map<String, dynamic> json) {
    return SalonBranch(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Branch Studio').toString(),
      code: (json['code'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      chairs: (json['chairs'] is num)
          ? (json['chairs'] as num).toInt()
          : int.tryParse('${json['chairs']}') ?? 6,
      isActive: json['isActive'] != false,
      upiId: (json['upiId'] ?? '').toString(),
      upiPayeeName: (json['upiPayeeName'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'address': address,
    'city': city,
    'phone': phone,
    'email': email,
    'chairs': chairs,
    'isActive': isActive,
    'upiId': upiId,
    'upiPayeeName': upiPayeeName,
  };
}

class RuvexiAppState extends ChangeNotifier {
  final RuvexiApiClient api = RuvexiApiClient();

  String salonId = "";
  String salonSlug = "";
  String salonName = "Ruvexi Salon & Spa";
  String salonLocation = "";
  String salonPhone = "";
  String salonGstin = "";
  String salonUpiId = "";
  int salonChairs = 6;

  String get salonAddress => salonLocation;
  String get salonCity => activeBranch?.city ?? "";
  String get activeBranchName => activeBranch?.name ?? (branches.isNotEmpty ? branches.first.name : "");

  // Subscription state (fetched live from Railway)
  String subscriptionStatus = "trial";
  String subscriptionPlan = "free_trial";
  bool isTrialActive = true;
  int trialDaysLeft = 7;
  String? trialEndsAt;
  String conciergeWhatsapp = "";
  String conciergeUpiId = "";

  // Role state (RBAC enforced)
  String backendRole = "SALON_RECEPTIONIST";
  String userRole = "Receptionist"; // UI display mode: "Owner" | "Receptionist"
  String userBranchId = "";

  bool get canSwitchRoles {
    final normalized = backendRole.toUpperCase();
    return normalized == "SALON_MANAGER" ||
        normalized == "OWNER" ||
        normalized == "MANAGER" ||
        normalized == "ADMIN" ||
        normalized == "MASTER_ADMIN";
  }

  /// Strictly checks whether the user has multi-branch authority to switch locations.
  /// Front desk receptionists are permanently locked to their single assigned branch.
  bool get canSwitchBranch => canSwitchRoles;

  double todayRevenue = 0.0;
  int todayAppointmentsCount = 0;
  int todayClientsCount = 0;
  double todayProfit = 0.0;

  bool isAuthenticated = false;
  bool isSyncing = false;
  String? lastSyncError;
  String currentUserName = "";
  String currentUserEmail = "";

  /// Dynamic time-based greeting (e.g. Good Morning, Good Afternoon, Good Evening)
  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return "Good Morning,";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon,";
    } else {
      return "Good Evening,";
    }
  }

  String _formatName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return "";
    return trimmed.split(RegExp(r'\s+')).map((part) {
      if (part.isEmpty) return "";
      return part[0].toUpperCase() + (part.length > 1 ? part.substring(1).toLowerCase() : "");
    }).join(' ');
  }

  /// Real user display name formatted cleanly (title-cased)
  String get displayName {
    if (currentUserName.trim().isNotEmpty) {
      return _formatName(currentUserName);
    }
    if (currentUserEmail.trim().isNotEmpty) {
      final prefix = currentUserEmail.split('@').first.trim();
      if (prefix.isNotEmpty) {
        return _formatName(prefix.replaceAll(RegExp(r'[._0-9]'), ' ').trim());
      }
    }
    return userRole == "Owner" ? "Salon Owner" : "Front Desk Receptionist";
  }

  /// Real user first name for friendly greetings
  String get displayFirstName {
    final name = displayName;
    if (name.isEmpty) return "Partner";
    return name.split(' ').first;
  }

  /// Single letter avatar initial
  String get userInitial {
    final name = displayName;
    if (name.isEmpty) return "R";
    return name[0].toUpperCase();
  }

  Customer? posSelectedCustomer;
  InSalonClient? activeBillingClient;
  int staffCompletedCount = 0;

  final List<SalonSeat> seats = [];
  final List<InSalonClient> inSalonClients = [];
  final List<ServiceItem> catalog = [];
  final List<PackageItem> packages = [];
  final List<Appointment> appointments = [];
  final List<Customer> customers = [];
  final List<StaffMember> staff = [];
  final List<InventoryItem> inventory = [];
  final List<ExpenseItem> expenses = [];
  final List<OfferItem> offers = [];
  final List<CartItem> posCart = [];
  final List<Map<String, dynamic>> invoices = [];
  final List<SalonBranch> branches = [];
  SalonBranch? activeBranch;

  double discountAmount = 0.0;

  RuvexiAppState() {
    api.onUnauthorized = () {
      _clearWorkspaceData();
      isAuthenticated = false;
      notifyListeners();
    };
  }

  void _rebuildSeats(int chairCount) {
    final count = chairCount.clamp(1, 24);
    seats.clear();
    for (int i = 1; i <= count; i++) {
      final seatId = "S-$i";
      final occupying = inSalonClients.where((c) => c.seatId == seatId && c.status == "In Salon").toList();
      seats.add(SalonSeat(
        id: seatId,
        isInUse: occupying.isNotEmpty,
        currentClientId: occupying.isNotEmpty ? occupying.first.id : null,
        currentClientName: occupying.isNotEmpty ? occupying.first.customerName : null,
      ));
    }
  }

  void _clearWorkspaceData() {
    salonId = "";
    salonSlug = "";
    salonName = "Ruvexi Salon & Spa";
    salonLocation = "";
    salonPhone = "";
    salonGstin = "";
    salonUpiId = "";
    salonChairs = 6;
    subscriptionStatus = "trial";
    subscriptionPlan = "free_trial";
    isTrialActive = true;
    trialDaysLeft = 7;
    trialEndsAt = null;
    conciergeWhatsapp = "";
    conciergeUpiId = "";
    backendRole = "SALON_RECEPTIONIST";
    userRole = "Receptionist";
    userBranchId = "";
    currentUserName = "";
    currentUserEmail = "";
    todayRevenue = 0.0;
    todayAppointmentsCount = 0;
    todayClientsCount = 0;
    todayProfit = 0.0;
    staffCompletedCount = 0;
    posSelectedCustomer = null;
    activeBillingClient = null;
    catalog.clear();
    customers.clear();
    staff.clear();
    inventory.clear();
    appointments.clear();
    expenses.clear();
    invoices.clear();
    inSalonClients.clear();
    seats.clear();
    posCart.clear();
    branches.clear();
    activeBranch = null;
  }

  void _applyUserAndSalon(Map<String, dynamic>? userMap, Map<String, dynamic>? salonMap) {
    if (userMap != null) {
      currentUserName = (userMap['name'] ?? '').toString();
      currentUserEmail = (userMap['email'] ?? '').toString();
      backendRole = (userMap['role'] ?? 'SALON_RECEPTIONIST').toString().toUpperCase();
      userBranchId = (userMap['branchId'] ?? userMap['branch_id'] ?? '').toString();
      userRole = canSwitchRoles ? 'Owner' : 'Receptionist';
      if (currentUserName.isNotEmpty) {
        api.setUserName(currentUserName);
      }
      if (currentUserEmail.isNotEmpty) {
        api.setUserEmail(currentUserEmail);
      }
    }
    if (salonMap != null) {
      salonId = (salonMap['id'] ?? '').toString();
      salonSlug = (salonMap['slug'] ?? '').toString();
      salonName = (salonMap['name'] ?? 'Ruvexi Salon & Spa').toString();
      final city = (salonMap['city'] ?? '').toString();
      final branch = (salonMap['branch'] ?? '').toString();
      salonLocation = city.isNotEmpty ? city : (branch.isNotEmpty ? branch : (salonMap['address'] ?? '').toString());
      salonPhone = (salonMap['phone'] ?? '').toString();
      salonGstin = (salonMap['gstin'] ?? '').toString();
      salonUpiId = (salonMap['upiId'] ?? '').toString();
      salonChairs = (salonMap['chairs'] is num) ? (salonMap['chairs'] as num).toInt() : 6;
      subscriptionStatus = (salonMap['subscriptionStatus'] ?? 'trial').toString();
      subscriptionPlan = (salonMap['subscriptionPlan'] ?? 'free_trial').toString();
      isTrialActive = salonMap['isTrialActive'] != false;
      trialDaysLeft = (salonMap['trialDaysLeft'] is num) ? (salonMap['trialDaysLeft'] as num).toInt() : 7;
      trialEndsAt = salonMap['trialEndsAt']?.toString();
    }
  }

  Future<bool> restoreSession() async {
    final token = await api.getToken();
    if (token == null || token.isEmpty) {
      isAuthenticated = false;
      notifyListeners();
      return false;
    }

    // Pre-hydrate cached user profile immediately for zero-flicker UI
    final cachedName = await api.getUserName();
    final cachedEmail = await api.getUserEmail();
    if (cachedName != null && cachedName.isNotEmpty) {
      currentUserName = cachedName;
    }
    if (cachedEmail != null && cachedEmail.isNotEmpty) {
      currentUserEmail = cachedEmail;
    }

    try {
      await syncWorkspace();
      isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      await api.clearToken();
      _clearWorkspaceData();
      isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String identifier, required String password}) async {
    lastSyncError = null;
    final res = await api.login(identifier: identifier, password: password);
    _applyUserAndSalon(
      res['user'] is Map ? Map<String, dynamic>.from(res['user']) : null,
      res['salon'] is Map ? Map<String, dynamic>.from(res['salon']) : null,
    );
    isAuthenticated = true;
    await syncWorkspace();
    notifyListeners();
    return true;
  }

  Future<bool> signup({
    required String ownerName,
    required String salonNameInput,
    required String email,
    required String password,
    String phone = '',
    String city = 'Bengaluru',
  }) async {
    lastSyncError = null;
    final res = await api.signup(
      ownerName: ownerName,
      salonName: salonNameInput,
      email: email,
      password: password,
      phone: phone,
      city: city,
    );
    _applyUserAndSalon(
      res['user'] is Map ? Map<String, dynamic>.from(res['user']) : null,
      res['salon'] is Map ? Map<String, dynamic>.from(res['salon']) : null,
    );
    isAuthenticated = true;
    await syncWorkspace();
    notifyListeners();
    return true;
  }

  Future<bool> loginWithGoogle() async {
    lastSyncError = null;
    String clientId = RuvexiApiConfig.googleClientId;
    if (clientId.isEmpty) {
      try {
        final cfg = await api.fetchPublicConfig();
        clientId = (cfg['googleClientId'] ?? '').toString();
      } catch (_) {}
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: clientId.isNotEmpty ? clientId : null,
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw RuvexiApiException('Google sign-in was cancelled.');
    }

    final auth = await account.authentication;
    if ((auth.idToken == null || auth.idToken!.isEmpty) &&
        (auth.accessToken == null || auth.accessToken!.isEmpty)) {
      throw RuvexiApiException('Could not obtain Google credentials. Please sign in with email & password.');
    }

    final res = await api.googleAuth(idToken: auth.idToken, accessToken: auth.accessToken);
    _applyUserAndSalon(
      res['user'] is Map ? Map<String, dynamic>.from(res['user']) : null,
      res['salon'] is Map ? Map<String, dynamic>.from(res['salon']) : null,
    );
    isAuthenticated = true;
    await syncWorkspace();
    notifyListeners();
    return true;
  }

  Future<void> requestPasswordReset(String email) async {
    await api.requestPasswordReset(email);
  }

  Future<void> requestOtp(String emailOrPhone) async {
    await api.requestOtp(emailOrPhone);
  }

  Future<bool> verifyOtp({
    String emailOrPhone = '',
    String? phone,
    required String otp,
  }) async {
    lastSyncError = null;
    final res = await api.verifyOtp(emailOrPhone: emailOrPhone, phone: phone, otp: otp);
    _applyUserAndSalon(
      res['user'] is Map ? Map<String, dynamic>.from(res['user']) : null,
      res['salon'] is Map ? Map<String, dynamic>.from(res['salon']) : null,
    );
    isAuthenticated = true;
    await syncWorkspace();
    notifyListeners();
    return true;
  }

  Future<void> syncWorkspace() async {
    isSyncing = true;
    lastSyncError = null;
    notifyListeners();

    try {
      // Run bootstrap + secondary workspace calls in parallel for fast startup
      final expensesFuture = api.fetchExpenses().catchError((_) => <dynamic>[]);
      final branchesFuture = api.fetchBranches().catchError((_) => <dynamic>[]);
      final data = await api.fetchBootstrap();
      _applyUserAndSalon(
        data['user'] is Map ? Map<String, dynamic>.from(data['user']) : null,
        data['salon'] is Map ? Map<String, dynamic>.from(data['salon']) : null,
      );

      final rawServices = (data['services'] as List?) ?? [];
      final parsedServices = rawServices.whereType<Map>().map((m) => ServiceItem.fromJson(Map<String, dynamic>.from(m))).toList();

      catalog
        ..clear()
        ..addAll(parsedServices);

      final rawCustomers = (data['customers'] as List?) ?? [];
      customers
        ..clear()
        ..addAll(rawCustomers.whereType<Map>().map((m) => Customer.fromJson(Map<String, dynamic>.from(m))));

      final rawStaff = (data['staff'] as List?) ?? [];
      staff
        ..clear()
        ..addAll(rawStaff.whereType<Map>().map((m) => StaffMember.fromJson(Map<String, dynamic>.from(m))));

      final rawInventory = (data['inventory'] as List?) ?? [];
      inventory
        ..clear()
        ..addAll(rawInventory.whereType<Map>().map((m) => InventoryItem.fromJson(Map<String, dynamic>.from(m))));

      final rawAppointments = (data['appointments'] as List?) ?? [];
      appointments
        ..clear()
        ..addAll(rawAppointments.whereType<Map>().map((m) => Appointment.fromJson(Map<String, dynamic>.from(m))));

      final rawInvoices = (data['invoices'] as List?) ?? [];
      invoices
        ..clear()
        ..addAll(rawInvoices.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));

      final parallelResults = await Future.wait<List<dynamic>>([expensesFuture, branchesFuture]);
      final rawExpenses = parallelResults[0];
      expenses
        ..clear()
        ..addAll(rawExpenses.whereType<Map>().map((m) => ExpenseItem.fromJson(Map<String, dynamic>.from(m))));

      final rawBranches = parallelResults[1];
      branches
        ..clear()
        ..addAll(rawBranches.whereType<Map>().map((m) => SalonBranch.fromJson(Map<String, dynamic>.from(m))));
      if (branches.isNotEmpty && (activeBranch == null || !branches.any((b) => b.id == activeBranch!.id))) {
        activeBranch = branches.first;
      }

      // Preserve existing active walk-ins while syncing appointment-based clients
      final existingWalkIns = inSalonClients.where((c) => c.status != 'Completed' && c.id.startsWith('ins_')).toList();
      final List<InSalonClient> updatedClients = [...existingWalkIns];
      int chairIdx = existingWalkIns.length + 1;
      for (final apt in appointments) {
        if (apt.status == 'In Service' && !updatedClients.any((c) => c.id == apt.id)) {
          final seatId = chairIdx <= salonChairs ? 'S-${chairIdx++}' : 'Waiting';
          final matchedServices = catalog.where((s) => s.name.toLowerCase() == apt.serviceName.toLowerCase()).toList();
          updatedClients.add(InSalonClient(
            id: apt.id,
            customerName: apt.customerName,
            phone: apt.customerPhone,
            services: matchedServices.isNotEmpty
                ? matchedServices
                : [ServiceItem(id: apt.id, name: apt.serviceName, category: 'Hair', price: apt.price, durationMinutes: apt.durationMinutes)],
            assignedStaff: apt.staffName,
            seatId: seatId,
            checkInTime: DateFormat('hh:mm a').format(apt.time),
            elapsedMinutes: DateTime.now().difference(apt.time).inMinutes.clamp(1, 180),
            status: seatId == 'Waiting' ? 'Waiting' : 'In Salon',
            notes: apt.notes,
          ));
        }
      }
      inSalonClients
        ..clear()
        ..addAll(updatedClients);
      _rebuildSeats(salonChairs);

      // Compute dashboard KPIs scoped to the active branch
      recalculateBranchMetrics();

      if (canSwitchRoles) {
        api.fetchReportsSummary().then((report) {
          if (report['netProfit'] is num) {
            todayProfit = (report['netProfit'] as num).toDouble();
            notifyListeners();
          }
        }).catchError((_) {});
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  void switchRole(String role) {
    if (!canSwitchRoles) return;
    if (role == "Owner" || role == "Receptionist") {
      userRole = role;
      notifyListeners();
    }
  }

  Future<void> updateSalonProfile({String? name, String? location, String? gstin, String? phone, String? address}) async {
    final trimmedName = name?.trim();
    final trimmedLoc = location?.trim();
    final trimmedGstin = gstin?.trim();
    final trimmedPhone = phone?.trim();
    final trimmedAddress = address?.trim();
    final updated = await api.updateSalonSettings({
      if (trimmedName != null && trimmedName.isNotEmpty) 'name': trimmedName,
      if (trimmedLoc != null && trimmedLoc.isNotEmpty) 'city': trimmedLoc,
      if (trimmedGstin != null && trimmedGstin.isNotEmpty) 'gstin': trimmedGstin,
      if (trimmedPhone != null && trimmedPhone.isNotEmpty) 'phone': trimmedPhone,
      if (trimmedAddress != null && trimmedAddress.isNotEmpty) 'address': trimmedAddress,
    });
    _applyUserAndSalon(null, updated);
    notifyListeners();
  }

  Future<void> updateSalonDetails({
    required String name,
    String? branch,
    String? city,
    String? address,
    String? phone,
    int? chairs,
  }) async {
    final updated = await api.updateSalonSettings({
      'name': name.trim(),
      if (branch != null && branch.trim().isNotEmpty) 'branch': branch.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (chairs != null) 'chairs': chairs,
    });
    _applyUserAndSalon(null, updated);
    notifyListeners();
  }

  Future<void> updateSalonPaymentSettings({required String upiId, String? payeeName}) async {
    final trimmedUpi = upiId.trim();
    salonUpiId = trimmedUpi;
    notifyListeners();
    try {
      final updated = await api.updateSalonSettings({
        'upiId': trimmedUpi,
        if (payeeName != null && payeeName.trim().isNotEmpty) 'upiPayeeName': payeeName.trim(),
      });
      _applyUserAndSalon(null, updated);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchBranches() async {
    try {
      final rawBranches = await api.fetchBranches();
      branches
        ..clear()
        ..addAll(rawBranches.whereType<Map>().map((m) => SalonBranch.fromJson(Map<String, dynamic>.from(m))));
      if (!canSwitchBranch && userBranchId.isNotEmpty) {
        final assigned = branches.where((b) => b.id == userBranchId || b.name.toLowerCase() == userBranchId.toLowerCase()).toList();
        if (assigned.isNotEmpty) {
          activeBranch = assigned.first;
        } else if (branches.isNotEmpty) {
          activeBranch = branches.first;
        }
      } else if (branches.isNotEmpty && (activeBranch == null || !branches.any((b) => b.id == activeBranch!.id))) {
        activeBranch = branches.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching branches: $e");
    }
  }

  Future<SalonBranch?> createBranch({
    required String name,
    required String city,
    String? address,
    String? phone,
    String? email,
    int chairs = 6,
    String? upiId,
    String? upiPayeeName,
  }) async {
    if (!canSwitchBranch) {
      debugPrint("Branch creation blocked: Receptionists cannot add branches.");
      return null;
    }
    final res = await api.createBranch({
      'name': name.trim(),
      'city': city.trim(),
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (upiId != null && upiId.trim().isNotEmpty) 'upiId': upiId.trim(),
      if (upiPayeeName != null && upiPayeeName.trim().isNotEmpty) 'upiPayeeName': upiPayeeName.trim(),
      'chairs': chairs,
      'isActive': true,
    });
    final newBranch = SalonBranch.fromJson(res);
    branches.add(newBranch);
    activeBranch ??= newBranch;
    notifyListeners();
    return newBranch;
  }

  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    if (!canSwitchBranch) {
      debugPrint("Branch update blocked: Receptionists cannot modify branches.");
      return;
    }
    final res = await api.updateBranch(branchId, data);
    final updated = SalonBranch.fromJson(res);
    final idx = branches.indexWhere((b) => b.id == branchId);
    if (idx != -1) {
      branches[idx] = updated;
    }
    if (activeBranch?.id == branchId) {
      activeBranch = updated;
    }
    notifyListeners();
  }

  Future<void> deleteBranch(String branchId) async {
    if (!canSwitchBranch) {
      debugPrint("Branch delete blocked: Receptionists cannot delete branches.");
      return;
    }
    await api.deleteBranch(branchId);
    branches.removeWhere((b) => b.id == branchId);
    if (activeBranch?.id == branchId) {
      activeBranch = branches.isNotEmpty ? branches.first : null;
    }
    notifyListeners();
  }

  /// Normal customers are isolated to their registered branch.
  /// Membership customers (Gold, Silver, Platinum, Diamond, VIP) are shared across ALL branches!
  List<Customer> get visibleCustomers {
    final curBranchId = activeBranch?.id;
    if (curBranchId == null || curBranchId.isEmpty) return customers;
    return customers.where((c) {
      if (c.hasActiveMembership) return true;
      return c.branchId.isEmpty || c.branchId == curBranchId;
    }).toList();
  }

  /// Branch-filtered appointments
  List<Appointment> get branchAppointments {
    final curBranchId = activeBranch?.id;
    if (curBranchId == null || curBranchId.isEmpty) return appointments;
    return appointments.where((a) => a.branchId.isEmpty || a.branchId == curBranchId || a.branchId == 'Flagship').toList();
  }

  /// Branch-filtered invoices
  List<Map<String, dynamic>> get branchInvoices {
    final curBranchId = activeBranch?.id;
    if (curBranchId == null || curBranchId.isEmpty) return invoices;
    return invoices.where((inv) {
      final bId = (inv['branchId'] ?? '').toString();
      return bId.isEmpty || bId == curBranchId;
    }).toList();
  }

  /// Branch-filtered expenses
  List<ExpenseItem> get branchExpenses {
    final curBranchId = activeBranch?.id;
    if (curBranchId == null || curBranchId.isEmpty) return expenses;
    return expenses.where((e) => e.branchId.isEmpty || e.branchId == curBranchId).toList();
  }

  double get branchTotalExpenses => branchExpenses.fold(0.0, (sum, e) => sum + e.amount);

  void recalculateBranchMetrics() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final branchInvs = branchInvoices;
    double revToday = 0.0;
    int completedCount = 0;
    for (final inv in branchInvs) {
      final status = (inv['status'] ?? '').toString().toLowerCase();
      final dateField = (inv['paidAt'] ?? inv['createdAt'] ?? inv['date'] ?? '').toString();
      if (status == 'paid' && dateField.startsWith(todayStr)) {
        revToday += (inv['grandTotal'] is num) ? (inv['grandTotal'] as num).toDouble() : 0.0;
        completedCount += 1;
      }
    }

    if (revToday == 0.0 && branchInvs.isNotEmpty) {
      for (final inv in branchInvs) {
        if ((inv['status'] ?? '').toString().toLowerCase() == 'paid') {
          revToday += (inv['grandTotal'] is num) ? (inv['grandTotal'] as num).toDouble() : 0.0;
          completedCount += 1;
        }
      }
    }

    final branchAppts = branchAppointments;
    todayRevenue = revToday;
    todayAppointmentsCount = branchAppts.where((a) => DateFormat('yyyy-MM-dd').format(a.time) == todayStr).length;
    if (todayAppointmentsCount == 0) todayAppointmentsCount = branchAppts.length;
    todayClientsCount = visibleCustomers.length;
    staffCompletedCount = completedCount;
    todayProfit = (revToday - branchTotalExpenses).clamp(0.0, double.infinity);
  }

  void setActiveBranch(SalonBranch branch) {
    if (!canSwitchBranch) {
      debugPrint("Branch switch blocked: Receptionists are locked to their assigned branch.");
      return;
    }
    activeBranch = branch;
    if (branch.chairs > 0) {
      salonChairs = branch.chairs;
      _rebuildSeats(branch.chairs);
    }
    final locParts = [branch.address, branch.city].where((s) => s.trim().isNotEmpty).toList();
    if (locParts.isNotEmpty) {
      salonLocation = locParts.join(", ");
    }
    if (branch.phone.trim().isNotEmpty) {
      salonPhone = branch.phone.trim();
    }
    recalculateBranchMetrics();
    notifyListeners();
  }

  Future<Map<String, dynamic>> inviteReceptionist({
    required String email,
    String? branchId,
  }) async {
    return await api.createReceptionistInvitation(
      email: email,
      branchId: branchId,
    );
  }

  int get inSalonActiveCount => inSalonClients.where((c) => c.status == "In Salon").length;
  int get waitingClientsCount => inSalonClients.where((c) => c.status == "Waiting").length;
  int get seatsInUseCount => seats.where((s) => s.isInUse).length;
  int get seatsAvailableCount => seats.where((s) => !s.isInUse).length;

  int get totalInventoryItemsCount => inventory.fold(0, (sum, i) => sum + i.stock);
  int get lowStockInventoryCount => inventory.where((i) => i.isLowStock).length;

  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);

  double get cartSubtotal => posCart.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  double get cartTax => 0.0; // Tax removed - owner sets prices and custom discounts directly
  double get cartTotalPayable => (cartSubtotal - discountAmount).clamp(0, double.infinity);

  void setDiscountAmount(double amount) {
    discountAmount = amount.clamp(0.0, cartSubtotal);
    notifyListeners();
  }

  void setDiscountPercent(double percent) {
    final pct = percent.clamp(0.0, 100.0);
    discountAmount = ((cartSubtotal * pct) / 100.0).roundToDouble();
    notifyListeners();
  }

  void updateCartQuantity(String serviceId, int delta) {
    final idx = posCart.indexWhere((c) => c.id == serviceId || c.service.id == serviceId);
    if (idx >= 0) {
      final newQty = posCart[idx].quantity + delta;
      if (newQty <= 0) {
        posCart.removeAt(idx);
      } else {
        posCart[idx].quantity = newQty;
      }
      notifyListeners();
    }
  }

  void addServiceToCart(ServiceItem service, {String? staffName}) {
    final idx = posCart.indexWhere((c) => !c.isProduct && c.id == service.id);
    if (idx >= 0) {
      posCart[idx].quantity += 1;
    } else {
      posCart.add(CartItem(
        service: service,
        type: 'service',
        staffName: staffName,
      ));
    }
    notifyListeners();
  }

  void addProductToCart(InventoryItem product, {String? staffName}) {
    final idx = posCart.indexWhere((c) => c.isProduct && c.id == product.id);
    if (idx >= 0) {
      posCart[idx].quantity += 1;
    } else {
      posCart.add(CartItem(
        product: product,
        type: 'product',
        staffName: staffName,
      ));
    }
    notifyListeners();
  }

  Future<void> addProduct(InventoryItem item) async {
    inventory.insert(0, item);
    notifyListeners();
    try {
      final created = await api.createInventoryItem({
        'name': item.name,
        'category': item.category,
        'retailPrice': item.price,
        'sellingPrice': item.price,
        'currentStock': item.stock,
        'brand': item.sizeVolume,
        'unit': item.unit,
      });
      inventory[0] = InventoryItem.fromJson(created);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating product: ');
    }
  }

  void clearCart() {
    posCart.clear();
    discountAmount = 0.0;
    notifyListeners();
  }

  void setPosCustomer(Customer? customer) {
    posSelectedCustomer = customer;
    notifyListeners();
  }

  Future<void> completePayment({
    required String method,
    double? amount,
    String? invoiceNumber,
    String? staffName,
  }) async {
    final total = amount ?? cartTotalPayable;
    final itemsPayload = posCart.isNotEmpty
        ? posCart
            .map((c) => {
                  'id': c.id,
                  'serviceId': c.isProduct ? null : c.id,
                  'productId': c.isProduct ? c.id : null,
                  'name': c.name,
                  'price': c.price,
                  'quantity': c.quantity,
                  'type': c.type,
                  'category': c.category,
                  'staffName': c.staffName ?? staffName ?? '',
                })
            .toList()
        : [
            {'name': 'Salon Service', 'price': total, 'quantity': 1, 'type': 'service', 'staffName': staffName ?? ''}
          ];

    final invNum = invoiceNumber?.isNotEmpty == true
        ? invoiceNumber!
        : 'RVX-${salonSlug.isNotEmpty ? salonSlug.toUpperCase() : "POS"}-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000000}';

    Map<String, dynamic>? res;
    try {
      res = await api.createInvoice({
        'invoiceNumber': invNum,
        if (salonUpiId.isNotEmpty) 'upiId': salonUpiId,
        if (posSelectedCustomer != null && !posSelectedCustomer!.id.startsWith('tmp_'))
          'customerId': posSelectedCustomer!.id,
        'customerName': posSelectedCustomer?.name ?? 'Walk-in Guest',
        'customerPhone': posSelectedCustomer?.phone ?? '',
        if (posSelectedCustomer != null && posSelectedCustomer!.gender.isNotEmpty)
          'gender': posSelectedCustomer!.gender,
        if (posSelectedCustomer != null && posSelectedCustomer!.dateOfBirth.isNotEmpty)
          'dob': posSelectedCustomer!.dateOfBirth,
        if (staffName != null && staffName.isNotEmpty) 'staffName': staffName,
        'items': itemsPayload,
        'subtotal': posCart.isNotEmpty ? cartSubtotal : total,
        'discountAmount': discountAmount,
        'taxPercent': 0.0,
        'paymentMethod': method,
        'status': 'paid',
        'branchId': activeBranch?.id ?? '',
      });
    } catch (e) {
      debugPrint("createInvoice remote sync notice: $e");
    }

    final invRecord = <String, dynamic>{
      'invoiceNumber': invNum,
      'branchId': activeBranch?.id ?? '',
      'customerName': posSelectedCustomer?.name ?? 'Walk-in Guest',
      'customerPhone': posSelectedCustomer?.phone ?? '',
      'items': itemsPayload,
      'subtotal': posCart.isNotEmpty ? cartSubtotal : total,
      'discountAmount': discountAmount,
      'taxAmount': 0.0,
      'grandTotal': total,
      'paymentMethod': method,
      'status': 'paid',
      'date': 'Today, ${DateFormat('hh:mm a').format(DateTime.now())}',
      'paidAt': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (res is Map<String, dynamic>) {
      invRecord.addAll(res);
    }
    invoices.removeWhere((i) => i['invoiceNumber'] == invNum);
    invoices.insert(0, invRecord);

    recalculateBranchMetrics();

    // Reset customer selection & billing session cleanly
    posSelectedCustomer = null;
    discountAmount = 0.0;
    if (activeBillingClient != null) {
      final client = activeBillingClient!;
      client.status = "Completed";
      if (!client.id.startsWith('ins_')) {
        updateAppointmentStatus(client.id, 'Completed').catchError((_) {});
      }
      final seatIdx = seats.indexWhere((s) => s.id == client.seatId);
      if (seatIdx >= 0) {
        seats[seatIdx].isInUse = false;
        seats[seatIdx].currentClientId = null;
        seats[seatIdx].currentClientName = null;
      }
      activeBillingClient = null;
    }

    clearCart();
    notifyListeners();

    // Run workspace refresh in background non-blocking
    syncWorkspace().catchError((e) {
      debugPrint("Background sync notice: $e");
    });
  }

  Future<void> addAppointment(Appointment appt) async {
    final effectiveBranchId = appt.branchId.isNotEmpty
        ? appt.branchId
        : (activeBranch?.id ?? 'Flagship');
    appointments.insert(0, appt);
    notifyListeners();
    try {
      final created = await api.createAppointment({
        'customerName': appt.customerName,
        'customerPhone': appt.customerPhone,
        'serviceName': appt.serviceName,
        'staffName': appt.staffName,
        'date': DateFormat('yyyy-MM-dd').format(appt.time),
        'startTime': DateFormat('HH:mm').format(appt.time),
        'durationMinutes': appt.durationMinutes,
        'price': appt.price,
        'status': appt.status.toLowerCase().replaceAll(' ', '_'),
        'notes': appt.notes,
        'source': 'mobile_app',
        'allowDoubleBooking': true,
        'branchId': effectiveBranchId,
      });
      appointments[0] = Appointment.fromJson(created);
      recalculateBranchMetrics();
      notifyListeners();
    } catch (e) {
      appointments.remove(appt);
      lastSyncError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAppointmentStatus(String id, String newStatus) async {
    final idx = appointments.indexWhere((a) => a.id == id);
    final previous = idx >= 0 ? appointments[idx].status : null;
    if (idx >= 0) {
      appointments[idx].status = newStatus;
      notifyListeners();
    }
    try {
      await api.updateAppointmentStatus(id, newStatus.toLowerCase().replaceAll(' ', '_'));
    } catch (e) {
      if (idx >= 0 && previous != null) {
        appointments[idx].status = previous;
      }
      lastSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    final effectiveBranchId = customer.branchId.isNotEmpty
        ? customer.branchId
        : (activeBranch?.id ?? '');
    final customerToSave = customer.copyWith(branchId: effectiveBranchId);
    customers.insert(0, customerToSave);
    notifyListeners();
    try {
      final created = await api.createCustomer({
        'name': customerToSave.name,
        'phone': customerToSave.phone,
        'email': customerToSave.email,
        'gender': customerToSave.gender,
        'birthday': customerToSave.dateOfBirth,
        'dob': customerToSave.dateOfBirth,
        'formulaNotes': customerToSave.formulaNotes ?? '',
        'vipTier': customerToSave.membership,
        'branchId': effectiveBranchId,
      });
      customers[0] = Customer.fromJson(created);
      recalculateBranchMetrics();
      notifyListeners();
    } catch (e) {
      customers.remove(customerToSave);
      lastSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> importCustomers(
    List<Map<String, dynamic>> customersList, {
    String duplicateStrategy = 'merge',
  }) async {
    try {
      final res = await api.importCustomers(customersList, duplicateStrategy: duplicateStrategy);
      await syncWorkspace();
      return res;
    } catch (e) {
      lastSyncError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCustomerFormula(String customerId, String formulaNotes) async {
    final idx = customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0) {
      final old = customers[idx];
      customers[idx] = Customer(
        id: old.id,
        name: old.name,
        phone: old.phone,
        email: old.email,
        tag: old.tag,
        visitsCount: old.visitsCount,
        totalSpent: old.totalSpent,
        membership: old.membership,
        formulaNotes: formulaNotes,
        loyaltyPoints: old.loyaltyPoints,
      );
      notifyListeners();
      try {
        await api.updateCustomer(customerId, {'formulaNotes': formulaNotes});
      } catch (e) {
        lastSyncError = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> updateCustomerMembership(String customerId, String newMembership, {int? loyaltyPoints}) async {
    final idx = customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0) {
      final old = customers[idx];
      customers[idx] = old.copyWith(
        membership: newMembership,
        loyaltyPoints: loyaltyPoints ?? old.loyaltyPoints,
      );
      if (posSelectedCustomer?.id == customerId) {
        posSelectedCustomer = customers[idx];
      }
      notifyListeners();
      try {
        final Map<String, dynamic> body = {'vipTier': newMembership};
        if (loyaltyPoints != null) {
          body['loyaltyPoints'] = loyaltyPoints;
        }
        await api.updateCustomer(customerId, body);
      } catch (e) {
        lastSyncError = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> addStaff(StaffMember staffMember) async {
    staff.add(staffMember);
    notifyListeners();
    try {
      final created = await api.createStaff({
        'name': staffMember.name,
        'role': staffMember.role,
        'phone': staffMember.phone,
        'commissionRate': staffMember.commissionRate * 100.0,
      });
      final idx = staff.indexOf(staffMember);
      if (idx >= 0) staff[idx] = StaffMember.fromJson(created);
      notifyListeners();
    } catch (e) {
      staff.remove(staffMember);
      lastSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleStaffClockIn(String id) async {
    final idx = staff.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      staff[idx].isClockedIn = !staff[idx].isClockedIn;
      notifyListeners();
      try {
        final updated = await api.toggleStaffClock(id);
        staff[idx] = StaffMember.fromJson(updated);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> addService(ServiceItem service) async {
    catalog.add(service);
    notifyListeners();
    try {
      final created = await api.createService({
        'name': service.name,
        'category': service.category,
        'price': service.price,
        'durationMinutes': service.durationMinutes,
      });
      final idx = catalog.indexOf(service);
      if (idx >= 0) catalog[idx] = ServiceItem.fromJson(created);
      notifyListeners();
    } catch (e) {
      catalog.remove(service);
      lastSyncError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    inventory.insert(0, item);
    notifyListeners();
    try {
      final created = await api.createInventoryItem({
        'name': item.name,
        'category': item.category,
        'currentStock': item.stock,
        'minThreshold': item.minAlert,
        'unit': item.unit,
        'brand': item.sizeVolume,
      });
      inventory[0] = InventoryItem.fromJson(created);
      notifyListeners();
    } catch (e) {
      inventory.remove(item);
      lastSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> addExpense(ExpenseItem item) async {
    expenses.insert(0, item);
    notifyListeners();
    try {
      final created = await api.createExpense({
        'title': item.note.isNotEmpty ? item.note : item.category,
        'category': item.category,
        'amount': item.amount,
        'date': DateFormat('yyyy-MM-dd').format(item.date),
        'notes': item.note,
      });
      expenses[0] = ExpenseItem.fromJson(created);
      notifyListeners();
    } catch (e) {
      expenses.remove(item);
      lastSyncError = e.toString();
      notifyListeners();
    }
  }

  void toggleOfferStatus(String id) {
    final idx = offers.indexWhere((o) => o.id == id);
    if (idx >= 0) {
      offers[idx].isActive = !offers[idx].isActive;
      notifyListeners();
    }
  }

  void addOffer(OfferItem offer) {
    offers.add(offer);
    notifyListeners();
  }

  Future<void> checkInCustomer({
    required String customerName,
    required String phone,
    required List<ServiceItem> services,
    required String assignedStaff,
    required String seatId,
    String notes = "",
    String gender = "Female",
    String dateOfBirth = "",
  }) async {
    if (customerName.isNotEmpty && customerName.toLowerCase() != "walk-in guest") {
      final exists = customers.any((c) => (phone.isNotEmpty && c.phone == phone) || c.name.toLowerCase() == customerName.toLowerCase());
      if (!exists) {
        addCustomer(Customer(
          id: "cst_${DateTime.now().millisecondsSinceEpoch}",
          name: customerName,
          phone: phone,
          email: "${customerName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@example.com",
          gender: gender,
          dateOfBirth: dateOfBirth,
          visitsCount: 1,
          totalSpent: 0.0,
        )).catchError((_) {});
      }
    }
    final tempId = "ins_${DateTime.now().millisecondsSinceEpoch}";
    final isWaiting = seatId == "Waiting";
    final now = TimeOfDayHelper.formatNow();

    final newClient = InSalonClient(
      id: tempId,
      customerName: customerName,
      phone: phone,
      services: services,
      assignedStaff: assignedStaff,
      seatId: seatId,
      checkInTime: now,
      elapsedMinutes: 1,
      status: isWaiting ? "Waiting" : "In Salon",
      notes: notes,
    );

    inSalonClients.insert(0, newClient);

    if (!isWaiting) {
      final seatIdx = seats.indexWhere((s) => s.id == seatId);
      if (seatIdx >= 0) {
        seats[seatIdx].isInUse = true;
        seats[seatIdx].currentClientId = tempId;
        seats[seatIdx].currentClientName = customerName;
      }
    }

    notifyListeners();

    try {
      final totalServicePrice = services.fold(0.0, (s, item) => s + item.price);
      final created = await api.createAppointment({
        'customerName': customerName,
        'customerPhone': phone,
        'serviceName': services.map((s) => s.name).join(' + '),
        'staffName': assignedStaff,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'startTime': DateFormat('HH:mm').format(DateTime.now()),
        'durationMinutes': services.fold(0, (s, item) => s + item.durationMinutes),
        'price': totalServicePrice > 0 ? totalServicePrice : 500.0,
        'status': 'in_service',
        'notes': notes,
        'source': 'front_desk',
        'allowDoubleBooking': true,
      });
      appointments.insert(0, Appointment.fromJson(created));
      notifyListeners();
    } catch (_) {}
  }

  void updateInSalonClient({
    required String clientId,
    String? newSeatId,
    String? newStaff,
    List<ServiceItem>? newServices,
  }) {
    final idx = inSalonClients.indexWhere((c) => c.id == clientId);
    if (idx < 0) return;

    final client = inSalonClients[idx];

    if (newSeatId != null && newSeatId != client.seatId) {
      final oldSeatIdx = seats.indexWhere((s) => s.id == client.seatId);
      if (oldSeatIdx >= 0) {
        seats[oldSeatIdx].isInUse = false;
        seats[oldSeatIdx].currentClientId = null;
        seats[oldSeatIdx].currentClientName = null;
      }
      if (newSeatId != "Waiting") {
        final newSeatIdx = seats.indexWhere((s) => s.id == newSeatId);
        if (newSeatIdx >= 0) {
          seats[newSeatIdx].isInUse = true;
          seats[newSeatIdx].currentClientId = client.id;
          seats[newSeatIdx].currentClientName = client.customerName;
        }
        client.status = "In Salon";
      } else {
        client.status = "Waiting";
      }
      client.seatId = newSeatId;
    }

    if (newStaff != null) client.assignedStaff = newStaff;
    if (newServices != null && newServices.isNotEmpty) client.services = newServices;

    notifyListeners();
  }

  void moveClientToBilling(InSalonClient client) {
    activeBillingClient = client;

    final existingIdx = customers.indexWhere((c) => c.name.toLowerCase() == client.customerName.toLowerCase());
    if (existingIdx >= 0) {
      posSelectedCustomer = customers[existingIdx];
    } else {
      posSelectedCustomer = Customer(
        id: "tmp_${client.id}",
        name: client.customerName,
        phone: client.phone,
        email: "",
        visitsCount: 1,
        totalSpent: 0,
      );
    }

    posCart.clear();
    for (final svc in client.services) {
      posCart.add(CartItem(service: svc, quantity: 1));
    }

    notifyListeners();
  }

  Future<void> completeStaffCheckout({
    required String method,
    required double amount,
    String? invoiceNumber,
    String? staffName,
  }) async {
    await completePayment(method: method, amount: amount, invoiceNumber: invoiceNumber, staffName: staffName);
  }

  Future<void> logout() async {
    await api.clearToken();
    _clearWorkspaceData();
    isAuthenticated = false;
    notifyListeners();
  }
}

class TimeOfDayHelper {
  static String formatNow() {
    final now = DateTime.now();
    final hour12 = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? "PM" : "AM";
    return "${hour12.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period";
  }
}
