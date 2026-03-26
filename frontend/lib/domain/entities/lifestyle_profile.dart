import 'dart:convert';

/// V63 — Lifestyle Matcher: LifestyleProfile entity
/// V63.1 — Ultra-matching engine additions (light, social, readiness weights)

enum LifestylePace {
  vibrant_center,
  calm_peripheral,
  residential_neighborhood,
  cultural_zone,
  rural,
}

enum WorkStyle {
  daily_office,
  home_office,
  hybrid,
  freelance,
}

enum MobilityStyle {
  public_transport,
  private_car,
  cycling,
  walking,
}

enum SleepSensitivity {
  high_noise_sensitivity,
  deep_sleeper,
  needs_darkness,
  night_owl,
}

enum GreenNeeds {
  needs_green,
  prefers_services,
  near_water,
  mountain_nature,
  historic_center,
}

enum ProfileType {
  single,
  couple,
  family_children,
  family_pets,
  senior,
  investor,
  student,
}

class LifestyleProfile {
  const LifestyleProfile({
    required this.pace,
    required this.workStyle,
    required this.mobility,
    required this.sleep,
    required this.greenNeeds,
    required this.profileType,
    this.naturalLightWeight = 0.5,
    this.socialWeight = 0.5,
    this.readyToLiveWeight = 0.5,
  });

  final LifestylePace pace;
  final WorkStyle workStyle;
  final MobilityStyle mobility;
  final SleepSensitivity sleep;
  final GreenNeeds greenNeeds;
  final ProfileType profileType;

  /// V63.1 — Weight for natural light preference vs cool climate (0.0 to 1.0)
  final double naturalLightWeight;

  /// V63.1 — Weight for social communal areas vs total privacy (0.0=private to 1.0=social)
  final double socialWeight;

  /// V63.1 — Weight for move-in ready vs reform potential (0.0=reform to 1.0=ready)
  final double readyToLiveWeight;

  String get profileName => _computeProfileName();
  String get profileDescription => _computeDescription();

  String _computeProfileName() {
    if (profileType == ProfileType.investor) return 'Inversor Estrategico';
    if (profileType == ProfileType.student) return 'Estudiante Urbano';
    if (profileType == ProfileType.family_children) return 'Familia Activa';
    if (pace == LifestylePace.rural) return 'Vida Rural Tranquila';
    if (pace == LifestylePace.cultural_zone) return 'Explorador Cultural';
    if (pace == LifestylePace.calm_peripheral &&
        sleep == SleepSensitivity.high_noise_sensitivity) {
      return 'Refugio Silencioso';
    }
    if (workStyle == WorkStyle.hybrid) return 'Profesional Hibrido';
    if (workStyle == WorkStyle.home_office &&
        mobility == MobilityStyle.public_transport) {
      return 'Urbano Conectado';
    }
    if (profileType == ProfileType.senior) return 'Bienestar Tranquilo';
    if (profileType == ProfileType.family_pets) return 'Familia con Mascotas';
    return 'Equilibrado Familiar';
  }

  String _computeDescription() {
    return 'Perfil optimizado para ${profileName.toLowerCase()}. Prioridades: ${_getPriorities()}.';
  }

  String _getPriorities() {
    final List<String> p = [];
    if (sleep == SleepSensitivity.high_noise_sensitivity) {
      p.add('tranquilidad');
    }
    if (greenNeeds == GreenNeeds.needs_green) p.add('zonas verdes');
    if (workStyle == WorkStyle.home_office) {
      p.add('espacio para teletrabajo');
    }
    if (naturalLightWeight > 0.7) p.add('luz natural');
    if (socialWeight < 0.3) p.add('privacidad');
    if (readyToLiveWeight < 0.3) p.add('potencial de reforma');
    return p.isEmpty ? 'calidad de vida' : p.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'pace': pace.name,
        'workStyle': workStyle.name,
        'mobility': mobility.name,
        'sleep': sleep.name,
        'greenNeeds': greenNeeds.name,
        'profileType': profileType.name,
        'naturalLightWeight': naturalLightWeight,
        'socialWeight': socialWeight,
        'readyToLiveWeight': readyToLiveWeight,
      };

  factory LifestyleProfile.fromJson(Map<String, dynamic> json) {
    return LifestyleProfile(
      pace: LifestylePace.values.firstWhere(
        (e) => e.name == json['pace'],
        orElse: () => LifestylePace.vibrant_center,
      ),
      workStyle: WorkStyle.values.firstWhere(
        (e) => e.name == json['workStyle'],
        orElse: () => WorkStyle.daily_office,
      ),
      mobility: MobilityStyle.values.firstWhere(
        (e) => e.name == json['mobility'],
        orElse: () => MobilityStyle.public_transport,
      ),
      sleep: SleepSensitivity.values.firstWhere(
        (e) => e.name == json['sleep'],
        orElse: () => SleepSensitivity.deep_sleeper,
      ),
      greenNeeds: GreenNeeds.values.firstWhere(
        (e) => e.name == json['greenNeeds'],
        orElse: () => GreenNeeds.prefers_services,
      ),
      profileType: ProfileType.values.firstWhere(
        (e) => e.name == json['profileType'],
        orElse: () => ProfileType.single,
      ),
      naturalLightWeight: (json['naturalLightWeight'] as num?)?.toDouble() ?? 0.5,
      socialWeight: (json['socialWeight'] as num?)?.toDouble() ?? 0.5,
      readyToLiveWeight: (json['readyToLiveWeight'] as num?)?.toDouble() ?? 0.5,
    );
  }

  static const defaultProfile = LifestyleProfile(
    pace: LifestylePace.vibrant_center,
    workStyle: WorkStyle.daily_office,
    mobility: MobilityStyle.public_transport,
    sleep: SleepSensitivity.deep_sleeper,
    greenNeeds: GreenNeeds.prefers_services,
    profileType: ProfileType.single,
    naturalLightWeight: 0.5,
    socialWeight: 0.5,
    readyToLiveWeight: 0.5,
  );

  LifestyleProfile copyWith({
    LifestylePace? pace,
    WorkStyle? workStyle,
    MobilityStyle? mobility,
    SleepSensitivity? sleep,
    GreenNeeds? greenNeeds,
    ProfileType? profileType,
    double? naturalLightWeight,
    double? socialWeight,
    double? readyToLiveWeight,
  }) {
    return LifestyleProfile(
      pace: pace ?? this.pace,
      workStyle: workStyle ?? this.workStyle,
      mobility: mobility ?? this.mobility,
      sleep: sleep ?? this.sleep,
      greenNeeds: greenNeeds ?? this.greenNeeds,
      profileType: profileType ?? this.profileType,
      naturalLightWeight: naturalLightWeight ?? this.naturalLightWeight,
      socialWeight: socialWeight ?? this.socialWeight,
      readyToLiveWeight: readyToLiveWeight ?? this.readyToLiveWeight,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static LifestyleProfile fromJsonString(String s) =>
      LifestyleProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
