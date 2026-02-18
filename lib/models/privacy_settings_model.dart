class PrivacySettingsModel {
  final bool shareLocation;
  final bool showOnlineStatus;
  final String profileVisibility; // 'all', 'connections', 'none'
  final String allowMessagesFrom; // 'all', 'connections', 'none'
  final bool shareCropData;

  PrivacySettingsModel({
    this.shareLocation = false,
    this.showOnlineStatus = true,
    this.profileVisibility = 'all',
    this.allowMessagesFrom = 'all',
    this.shareCropData = true,
  });

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) {
    return PrivacySettingsModel(
      shareLocation: json['share_location'] ?? false,
      showOnlineStatus: json['show_online_status'] ?? true,
      profileVisibility: json['profile_visibility'] ?? 'all',
      allowMessagesFrom: json['allow_messages_from'] ?? 'all',
      shareCropData: json['share_crop_data'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'share_location': shareLocation,
      'show_online_status': showOnlineStatus,
      'profile_visibility': profileVisibility,
      'allow_messages_from': allowMessagesFrom,
      'share_crop_data': shareCropData,
    };
  }

  PrivacySettingsModel copyWith({
    bool? shareLocation,
    bool? showOnlineStatus,
    String? profileVisibility,
    String? allowMessagesFrom,
    bool? shareCropData,
  }) {
    return PrivacySettingsModel(
      shareLocation: shareLocation ?? this.shareLocation,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      allowMessagesFrom: allowMessagesFrom ?? this.allowMessagesFrom,
      shareCropData: shareCropData ?? this.shareCropData,
    );
  }
}
