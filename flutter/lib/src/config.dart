import 'dart:convert';

import 'package:flutter/material.dart';

Map<String, dynamic> asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> asList(dynamic value) =>
    value is List ? value : const <dynamic>[];

String asString(dynamic value, [String fallback = '']) =>
    value?.toString() ?? fallback;

int asInt(dynamic value, [int fallback = 0]) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

bool asBool(dynamic value, [bool fallback = false]) =>
    value is bool ? value : fallback;

Color colorFromHex(String value, Color fallback) {
  final cleaned = value.replaceFirst('#', '');
  final normalized = cleaned.length == 8 ? cleaned : 'FF$cleaned';
  final parsed = int.tryParse(normalized, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

class Palette {
  Palette({
    required this.backgroundHex,
    required this.surfaceHex,
    required this.textHex,
    required this.accentHex,
    required this.primaryHex,
    required this.secondaryHex,
    required this.accentAltHex,
    required this.borderHex,
    required this.mutedHex,
    required this.onPrimaryHex,
  });

  factory Palette.fromJson(Map<String, dynamic> json) => Palette(
        backgroundHex: asString(json['background'], '#E8F3F2'),
        surfaceHex: asString(json['surface'], '#FFFFFF'),
        textHex: asString(json['text'], '#263238'),
        accentHex: asString(json['accent'], '#62B58A'),
        primaryHex: asString(json['primary'], '#078F91'),
        secondaryHex: asString(json['secondary'], '#1769A5'),
        accentAltHex: asString(json['accentAlt'], '#62B58A'),
        borderHex: asString(json['border'], '#DCE5E5'),
        mutedHex: asString(json['muted'], '#78909C'),
        onPrimaryHex: asString(json['onPrimary'], '#FFFFFF'),
      );

  final String backgroundHex;
  final String surfaceHex;
  final String textHex;
  final String accentHex;
  final String primaryHex;
  final String secondaryHex;
  final String accentAltHex;
  final String borderHex;
  final String mutedHex;
  final String onPrimaryHex;

  Color get background => colorFromHex(backgroundHex, const Color(0xFFE8F3F2));
  Color get surface => colorFromHex(surfaceHex, Colors.white);
  Color get onSurface => colorFromHex(textHex, const Color(0xFF263238));
  Color get accent => colorFromHex(accentHex, const Color(0xFF62B58A));
  Color get primary => colorFromHex(primaryHex, const Color(0xFF078F91));
  Color get secondary => colorFromHex(secondaryHex, const Color(0xFF1769A5));
  Color get accentAlt => colorFromHex(accentAltHex, const Color(0xFF62B58A));
  Color get border => colorFromHex(borderHex, const Color(0xFFDCE5E5));
  Color get muted => colorFromHex(mutedHex, const Color(0xFF78909C));
  Color get onPrimary => colorFromHex(onPrimaryHex, Colors.white);
}

class ActionConfig {
  ActionConfig({required this.label, required this.action, required this.style});

  factory ActionConfig.fromJson(Map<String, dynamic> json) => ActionConfig(
        label: asString(json['label'], 'Open'),
        action: asString(json['action']),
        style: asString(json['style'], 'primary'),
      );

  final String label;
  final String action;
  final String style;
}

class GridItem {
  GridItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.action,
    required this.visible,
  });

  factory GridItem.fromJson(Map<String, dynamic> json) => GridItem(
        id: asString(json['id']),
        label: asString(json['label']),
        icon: asString(json['icon'], 'ic_placeholder'),
        action: asString(json['action'], asString(json['id'])),
        visible: asBool(json['visible'], true),
      );

  final String id;
  final String label;
  final String icon;
  final String action;
  final bool visible;
}

class NavItem {
  NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.action,
    required this.visible,
  });

  factory NavItem.fromJson(Map<String, dynamic> json) => NavItem(
        id: asString(json['id']),
        label: asString(json['label']),
        icon: asString(json['icon'], 'ic_placeholder'),
        action: asString(json['action'], asString(json['id'])),
        visible: asBool(json['visible'], true),
      );

  final String id;
  final String label;
  final String icon;
  final String action;
  final bool visible;
}

class HeaderConfig {
  HeaderConfig({
    required this.brand,
    required this.title,
    required this.subtitle,
    required this.showNotification,
    required this.notificationAction,
    required this.height,
  });

  factory HeaderConfig.fromJson(Map<String, dynamic> json) => HeaderConfig(
        brand: asString(json['brand'], 'ALSEFA'),
        title: asString(json['title'], 'Alsefa Physiotherapy Center'),
        subtitle: asString(json['subtitle'], 'Physiotherapy & Rehabilitation Center'),
        showNotification: asBool(json['showNotification'], true),
        notificationAction: asString(json['notificationAction'], 'notifications'),
        height: asInt(json['heightDp'], 48).toDouble(),
      );

  final String brand;
  final String title;
  final String subtitle;
  final bool showNotification;
  final String notificationAction;
  final double height;
}

class BannerConfig {
  BannerConfig({
    required this.title,
    required this.headline,
    required this.body,
    required this.image,
    required this.action,
    required this.height,
    required this.cornerRadius,
    required this.backgroundColor,
  });

  factory BannerConfig.fromJson(Map<String, dynamic> json) => BannerConfig(
        title: asString(json['title']),
        headline: asString(json['headline']),
        body: asString(json['body']),
        image: asString(json['image'], 'ic_banner_physio'),
        action: asString(json['action']),
        height: asInt(json['heightDp'], 140).toDouble(),
        cornerRadius: asInt(json['cornerRadiusDp'], 8).toDouble(),
        backgroundColor: asString(json['backgroundColor'], '#E4F4F1'),
      );

  final String title;
  final String headline;
  final String body;
  final String image;
  final String action;
  final double height;
  final double cornerRadius;
  final String backgroundColor;
}

class GridConfig {
  GridConfig({
    required this.columns,
    required this.spacing,
    required this.cornerRadius,
    required this.items,
  });

  factory GridConfig.fromJson(Map<String, dynamic> json) => GridConfig(
        columns: asInt(json['columns'], 3),
        spacing: asInt(json['spacingDp'], 8).toDouble(),
        cornerRadius: asInt(json['cornerRadiusDp'], 8).toDouble(),
        items: asList(json['items'])
            .map((item) => GridItem.fromJson(asMap(item)))
            .toList(),
      );

  final int columns;
  final double spacing;
  final double cornerRadius;
  final List<GridItem> items;
}

class BottomNavConfig {
  BottomNavConfig({required this.height, required this.items});

  factory BottomNavConfig.fromJson(Map<String, dynamic> json) => BottomNavConfig(
        height: asInt(json['heightDp'], 56).toDouble(),
        items: asList(json['items'])
            .map((item) => NavItem.fromJson(asMap(item)))
            .toList(),
      );

  final double height;
  final List<NavItem> items;
}

class ScreenConfig {
  ScreenConfig({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.actions,
  });

  factory ScreenConfig.fromJson(Map<String, dynamic> json) => ScreenConfig(
        id: asString(json['id']),
        title: asString(json['title'], 'Alsefa'),
        message: asString(json['message']),
        icon: asString(json['icon'], 'ic_placeholder'),
        actions: asList(json['actions'])
            .map((action) => ActionConfig.fromJson(asMap(action)))
            .toList(),
      );

  final String id;
  final String title;
  final String message;
  final String icon;
  final List<ActionConfig> actions;
}

class RemoteConfig {
  RemoteConfig({
    required this.schemaVersion,
    required this.minimumAppVersion,
    required this.themeMode,
    required this.palette,
    required this.features,
    required this.appName,
    required this.brand,
    required this.subtitle,
    required this.header,
    required this.banner,
    required this.grid,
    required this.bottomNavigation,
    required this.screens,
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    final theme = asMap(json['theme']);
    final mode = asString(theme['mode'], 'light');
    final paletteJson = asMap(mode == 'dark' ? theme['dark'] : theme['light']);
    final branding = asMap(json['branding']);

    return RemoteConfig(
      schemaVersion: asInt(json['schemaVersion'], 1),
      minimumAppVersion: asInt(json['minimumAppVersion'], 1),
      themeMode: mode,
      palette: Palette.fromJson(paletteJson),
      features: asMap(json['features']),
      appName: asString(branding['appName'], 'Alsefa Physiotherapy Center'),
      brand: asString(branding['brand'], 'ALSEFA'),
      subtitle: asString(branding['subtitle'], 'Physiotherapy & Rehabilitation Center'),
      header: HeaderConfig.fromJson(asMap(json['header'])),
      banner: BannerConfig.fromJson(asMap(json['banner'])),
      grid: GridConfig.fromJson(asMap(json['grid'])),
      bottomNavigation: BottomNavConfig.fromJson(asMap(json['bottomNavigation'])),
      screens: asList(json['screens'])
          .map((screen) => ScreenConfig.fromJson(asMap(screen)))
          .toList(),
    );
  }

  factory RemoteConfig.fromPayload(String payload) =>
      RemoteConfig.fromJson(asMap(jsonDecode(payload)));

  final int schemaVersion;
  final int minimumAppVersion;
  final String themeMode;
  final Palette palette;
  final Map<String, dynamic> features;
  final String appName;
  final String brand;
  final String subtitle;
  final HeaderConfig header;
  final BannerConfig banner;
  final GridConfig grid;
  final BottomNavConfig bottomNavigation;
  final List<ScreenConfig> screens;

  bool featureEnabled(String name) => asBool(features[name], false);

  ScreenConfig? screenById(String id) {
    for (final screen in screens) {
      if (screen.id == id) return screen;
    }
    return null;
  }
}
