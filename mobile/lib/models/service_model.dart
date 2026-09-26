/// Data models for FreeTier Radar, aligned with the backend API schema.

import 'package:flutter/material.dart';

enum ServiceCategory {
  ALL,
  AI_ML,
  DATABASES,
  HOSTING_PAAS,
  AUTH_SECURITY,
  STORAGE_CDN,
  APIS_DEVTOOLS,
  CREATIVE_ASSETS;

  String get displayName {
    switch (this) {
      case ServiceCategory.AI_ML: return 'AI/ML';
      case ServiceCategory.DATABASES: return 'Databases';
      case ServiceCategory.HOSTING_PAAS: return 'Hosting';
      case ServiceCategory.AUTH_SECURITY: return 'Auth';
      case ServiceCategory.STORAGE_CDN: return 'Storage/CDN';
      case ServiceCategory.APIS_DEVTOOLS: return 'APIs & Tools';
      case ServiceCategory.CREATIVE_ASSETS: return 'Creative';
      case ServiceCategory.ALL: return 'All';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.AI_ML: return Icons.psychology;
      case ServiceCategory.DATABASES: return Icons.storage;
      case ServiceCategory.HOSTING_PAAS: return Icons.cloud;
      case ServiceCategory.AUTH_SECURITY: return Icons.lock;
      case ServiceCategory.STORAGE_CDN: return Icons.folder;
      case ServiceCategory.APIS_DEVTOOLS: return Icons.code;
      case ServiceCategory.CREATIVE_ASSETS: return Icons.palette;
      case ServiceCategory.ALL: return Icons.apps;
    }
  }
}

enum ServiceStatus {
  ACTIVE,
  CHANGED_RECENTLY,
  DEPRECATED;

  String get displayName {
    switch (this) {
      case ServiceStatus.ACTIVE: return 'Active';
      case ServiceStatus.CHANGED_RECENTLY: return 'Updated';
      case ServiceStatus.DEPRECATED: return 'Deprecated';
    }
  }
}

class ServiceItem {
  final String id;
  final String name;
  final ServiceCategory category;
  final String shortDescription;
  final String freeTierLimits;
  final bool requiresCreditCard;
  final bool hasHardCap;
  final String officialUrl;
  final String? pricingUrl;
  final ServiceStatus status;
  final String? changeLogSummary;
  final DateTime lastVerifiedAt;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.shortDescription,
    required this.freeTierLimits,
    required this.requiresCreditCard,
    required this.hasHardCap,
    required this.officialUrl,
    this.pricingUrl,
    required this.status,
    this.changeLogSummary,
    required this.lastVerifiedAt,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ServiceCategory.APIS_DEVTOOLS,
      ),
      shortDescription: json['short_description'] as String? ?? '',
      freeTierLimits: json['free_tier_limits'] as String? ?? 'See official docs',
      requiresCreditCard: json['requires_credit_card'] as bool? ?? false,
      hasHardCap: json['has_hard_cap'] as bool? ?? true,
      officialUrl: json['official_url'] as String? ?? '',
      pricingUrl: json['pricing_url'] as String?,
      status: ServiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ServiceStatus.ACTIVE,
      ),
      changeLogSummary: json['change_log_summary'] as String?,
      lastVerifiedAt: json['last_verified_at'] != null
          ? DateTime.parse(json['last_verified_at'])
          : DateTime.now(),
    );
  }
}

/// Advanced DeprecationAlert model containing old and new limits
class DeprecationAlert {
  final String id;
  final String serviceId;
  final String serviceName; // Added from new spec
  final String alertType; 
  final String summary;
  final String? oldLimit; // Added from new spec
  final String? newLimit; // Added from new spec
  final DateTime detectedAt;

  const DeprecationAlert({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.alertType,
    required this.summary,
    this.oldLimit,
    this.newLimit,
    required this.detectedAt,
  });

  factory DeprecationAlert.fromJson(Map<String, dynamic> json) {
    return DeprecationAlert(
      id: json['id'] as String? ?? '',
      serviceId: json['service_id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? 'Unknown Service',
      alertType: json['alert_type'] as String? ?? 'POLICY_CHANGE',
      summary: json['summary'] as String? ?? '',
      oldLimit: json['old_limit'] as String?,
      newLimit: json['new_limit'] as String?,
      detectedAt: json['detected_at'] != null
          ? DateTime.parse(json['detected_at'])
          : DateTime.now(),
    );
  }
}

class PaginatedServices {
  final List<ServiceItem> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedServices({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedServices.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return PaginatedServices(
      items: list.map((e) => ServiceItem.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }
}
