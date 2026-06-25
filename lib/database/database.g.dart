// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ActiveMatchesTable extends ActiveMatches
    with TableInfo<$ActiveMatchesTable, ActiveMatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveMatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      check: () => type.equals('singles') | type.equals('doubles'),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _scoringRuleMeta =
      const VerificationMeta('scoringRule');
  @override
  late final GeneratedColumn<String> scoringRule = GeneratedColumn<String>(
      'scoring_rule', aliasedName, false,
      check: () => scoringRule.equals('sideout') | scoringRule.equals('rally'),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _gameCountMeta =
      const VerificationMeta('gameCount');
  @override
  late final GeneratedColumn<int> gameCount = GeneratedColumn<int>(
      'game_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _playToMeta = const VerificationMeta('playTo');
  @override
  late final GeneratedColumn<int> playTo = GeneratedColumn<int>(
      'play_to', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(11));
  static const VerificationMeta _winByMeta = const VerificationMeta('winBy');
  @override
  late final GeneratedColumn<int> winBy = GeneratedColumn<int>(
      'win_by', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      check: () =>
          status.equals('setup') |
          status.equals('live') |
          status.equals('paused'),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('setup'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, scoringRule, gameCount, playTo, winBy, createdAt, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_matches';
  @override
  VerificationContext validateIntegrity(Insertable<ActiveMatche> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('scoring_rule')) {
      context.handle(
          _scoringRuleMeta,
          scoringRule.isAcceptableOrUnknown(
              data['scoring_rule']!, _scoringRuleMeta));
    } else if (isInserting) {
      context.missing(_scoringRuleMeta);
    }
    if (data.containsKey('game_count')) {
      context.handle(_gameCountMeta,
          gameCount.isAcceptableOrUnknown(data['game_count']!, _gameCountMeta));
    }
    if (data.containsKey('play_to')) {
      context.handle(_playToMeta,
          playTo.isAcceptableOrUnknown(data['play_to']!, _playToMeta));
    }
    if (data.containsKey('win_by')) {
      context.handle(
          _winByMeta, winBy.isAcceptableOrUnknown(data['win_by']!, _winByMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveMatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveMatche(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      scoringRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scoring_rule'])!,
      gameCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}game_count'])!,
      playTo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}play_to'])!,
      winBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}win_by'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $ActiveMatchesTable createAlias(String alias) {
    return $ActiveMatchesTable(attachedDatabase, alias);
  }
}

class ActiveMatche extends DataClass implements Insertable<ActiveMatche> {
  final int id;
  final String type;
  final String scoringRule;
  final int gameCount;
  final int playTo;
  final int winBy;
  final DateTime createdAt;
  final String status;
  const ActiveMatche(
      {required this.id,
      required this.type,
      required this.scoringRule,
      required this.gameCount,
      required this.playTo,
      required this.winBy,
      required this.createdAt,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['scoring_rule'] = Variable<String>(scoringRule);
    map['game_count'] = Variable<int>(gameCount);
    map['play_to'] = Variable<int>(playTo);
    map['win_by'] = Variable<int>(winBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  ActiveMatchesCompanion toCompanion(bool nullToAbsent) {
    return ActiveMatchesCompanion(
      id: Value(id),
      type: Value(type),
      scoringRule: Value(scoringRule),
      gameCount: Value(gameCount),
      playTo: Value(playTo),
      winBy: Value(winBy),
      createdAt: Value(createdAt),
      status: Value(status),
    );
  }

  factory ActiveMatche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveMatche(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      scoringRule: serializer.fromJson<String>(json['scoringRule']),
      gameCount: serializer.fromJson<int>(json['gameCount']),
      playTo: serializer.fromJson<int>(json['playTo']),
      winBy: serializer.fromJson<int>(json['winBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'scoringRule': serializer.toJson<String>(scoringRule),
      'gameCount': serializer.toJson<int>(gameCount),
      'playTo': serializer.toJson<int>(playTo),
      'winBy': serializer.toJson<int>(winBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
    };
  }

  ActiveMatche copyWith(
          {int? id,
          String? type,
          String? scoringRule,
          int? gameCount,
          int? playTo,
          int? winBy,
          DateTime? createdAt,
          String? status}) =>
      ActiveMatche(
        id: id ?? this.id,
        type: type ?? this.type,
        scoringRule: scoringRule ?? this.scoringRule,
        gameCount: gameCount ?? this.gameCount,
        playTo: playTo ?? this.playTo,
        winBy: winBy ?? this.winBy,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
      );
  ActiveMatche copyWithCompanion(ActiveMatchesCompanion data) {
    return ActiveMatche(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      scoringRule:
          data.scoringRule.present ? data.scoringRule.value : this.scoringRule,
      gameCount: data.gameCount.present ? data.gameCount.value : this.gameCount,
      playTo: data.playTo.present ? data.playTo.value : this.playTo,
      winBy: data.winBy.present ? data.winBy.value : this.winBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveMatche(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('scoringRule: $scoringRule, ')
          ..write('gameCount: $gameCount, ')
          ..write('playTo: $playTo, ')
          ..write('winBy: $winBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, type, scoringRule, gameCount, playTo, winBy, createdAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveMatche &&
          other.id == this.id &&
          other.type == this.type &&
          other.scoringRule == this.scoringRule &&
          other.gameCount == this.gameCount &&
          other.playTo == this.playTo &&
          other.winBy == this.winBy &&
          other.createdAt == this.createdAt &&
          other.status == this.status);
}

class ActiveMatchesCompanion extends UpdateCompanion<ActiveMatche> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> scoringRule;
  final Value<int> gameCount;
  final Value<int> playTo;
  final Value<int> winBy;
  final Value<DateTime> createdAt;
  final Value<String> status;
  const ActiveMatchesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.scoringRule = const Value.absent(),
    this.gameCount = const Value.absent(),
    this.playTo = const Value.absent(),
    this.winBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  ActiveMatchesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String scoringRule,
    this.gameCount = const Value.absent(),
    this.playTo = const Value.absent(),
    this.winBy = const Value.absent(),
    required DateTime createdAt,
    this.status = const Value.absent(),
  })  : type = Value(type),
        scoringRule = Value(scoringRule),
        createdAt = Value(createdAt);
  static Insertable<ActiveMatche> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? scoringRule,
    Expression<int>? gameCount,
    Expression<int>? playTo,
    Expression<int>? winBy,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (scoringRule != null) 'scoring_rule': scoringRule,
      if (gameCount != null) 'game_count': gameCount,
      if (playTo != null) 'play_to': playTo,
      if (winBy != null) 'win_by': winBy,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
    });
  }

  ActiveMatchesCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String>? scoringRule,
      Value<int>? gameCount,
      Value<int>? playTo,
      Value<int>? winBy,
      Value<DateTime>? createdAt,
      Value<String>? status}) {
    return ActiveMatchesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      scoringRule: scoringRule ?? this.scoringRule,
      gameCount: gameCount ?? this.gameCount,
      playTo: playTo ?? this.playTo,
      winBy: winBy ?? this.winBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (scoringRule.present) {
      map['scoring_rule'] = Variable<String>(scoringRule.value);
    }
    if (gameCount.present) {
      map['game_count'] = Variable<int>(gameCount.value);
    }
    if (playTo.present) {
      map['play_to'] = Variable<int>(playTo.value);
    }
    if (winBy.present) {
      map['win_by'] = Variable<int>(winBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveMatchesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('scoringRule: $scoringRule, ')
          ..write('gameCount: $gameCount, ')
          ..write('playTo: $playTo, ')
          ..write('winBy: $winBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $ActiveMatchPlayersTable extends ActiveMatchPlayers
    with TableInfo<$ActiveMatchPlayersTable, ActiveMatchPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveMatchPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _matchIdMeta =
      const VerificationMeta('matchId');
  @override
  late final GeneratedColumn<int> matchId = GeneratedColumn<int>(
      'match_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES active_matches (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamMeta = const VerificationMeta('team');
  @override
  late final GeneratedColumn<String> team = GeneratedColumn<String>(
      'team', aliasedName, false,
      check: () => team.equals('A') | team.equals('B'),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isStartingServerMeta =
      const VerificationMeta('isStartingServer');
  @override
  late final GeneratedColumn<bool> isStartingServer = GeneratedColumn<bool>(
      'is_starting_server', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_starting_server" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, true,
      check: () => position.equals('left') | position.equals('right'),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _serverNumberMeta =
      const VerificationMeta('serverNumber');
  @override
  late final GeneratedColumn<int> serverNumber = GeneratedColumn<int>(
      'server_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, matchId, name, team, isStartingServer, position, serverNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_match_players';
  @override
  VerificationContext validateIntegrity(Insertable<ActiveMatchPlayer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_id')) {
      context.handle(_matchIdMeta,
          matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta));
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('team')) {
      context.handle(
          _teamMeta, team.isAcceptableOrUnknown(data['team']!, _teamMeta));
    } else if (isInserting) {
      context.missing(_teamMeta);
    }
    if (data.containsKey('is_starting_server')) {
      context.handle(
          _isStartingServerMeta,
          isStartingServer.isAcceptableOrUnknown(
              data['is_starting_server']!, _isStartingServerMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('server_number')) {
      context.handle(
          _serverNumberMeta,
          serverNumber.isAcceptableOrUnknown(
              data['server_number']!, _serverNumberMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveMatchPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveMatchPlayer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      matchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}match_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      team: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team'])!,
      isStartingServer: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_starting_server'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position']),
      serverNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_number']),
    );
  }

  @override
  $ActiveMatchPlayersTable createAlias(String alias) {
    return $ActiveMatchPlayersTable(attachedDatabase, alias);
  }
}

class ActiveMatchPlayer extends DataClass
    implements Insertable<ActiveMatchPlayer> {
  final int id;
  final int matchId;
  final String name;
  final String team;
  final bool isStartingServer;
  final String? position;
  final int? serverNumber;
  const ActiveMatchPlayer(
      {required this.id,
      required this.matchId,
      required this.name,
      required this.team,
      required this.isStartingServer,
      this.position,
      this.serverNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_id'] = Variable<int>(matchId);
    map['name'] = Variable<String>(name);
    map['team'] = Variable<String>(team);
    map['is_starting_server'] = Variable<bool>(isStartingServer);
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(position);
    }
    if (!nullToAbsent || serverNumber != null) {
      map['server_number'] = Variable<int>(serverNumber);
    }
    return map;
  }

  ActiveMatchPlayersCompanion toCompanion(bool nullToAbsent) {
    return ActiveMatchPlayersCompanion(
      id: Value(id),
      matchId: Value(matchId),
      name: Value(name),
      team: Value(team),
      isStartingServer: Value(isStartingServer),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      serverNumber: serverNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serverNumber),
    );
  }

  factory ActiveMatchPlayer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveMatchPlayer(
      id: serializer.fromJson<int>(json['id']),
      matchId: serializer.fromJson<int>(json['matchId']),
      name: serializer.fromJson<String>(json['name']),
      team: serializer.fromJson<String>(json['team']),
      isStartingServer: serializer.fromJson<bool>(json['isStartingServer']),
      position: serializer.fromJson<String?>(json['position']),
      serverNumber: serializer.fromJson<int?>(json['serverNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchId': serializer.toJson<int>(matchId),
      'name': serializer.toJson<String>(name),
      'team': serializer.toJson<String>(team),
      'isStartingServer': serializer.toJson<bool>(isStartingServer),
      'position': serializer.toJson<String?>(position),
      'serverNumber': serializer.toJson<int?>(serverNumber),
    };
  }

  ActiveMatchPlayer copyWith(
          {int? id,
          int? matchId,
          String? name,
          String? team,
          bool? isStartingServer,
          Value<String?> position = const Value.absent(),
          Value<int?> serverNumber = const Value.absent()}) =>
      ActiveMatchPlayer(
        id: id ?? this.id,
        matchId: matchId ?? this.matchId,
        name: name ?? this.name,
        team: team ?? this.team,
        isStartingServer: isStartingServer ?? this.isStartingServer,
        position: position.present ? position.value : this.position,
        serverNumber:
            serverNumber.present ? serverNumber.value : this.serverNumber,
      );
  ActiveMatchPlayer copyWithCompanion(ActiveMatchPlayersCompanion data) {
    return ActiveMatchPlayer(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      name: data.name.present ? data.name.value : this.name,
      team: data.team.present ? data.team.value : this.team,
      isStartingServer: data.isStartingServer.present
          ? data.isStartingServer.value
          : this.isStartingServer,
      position: data.position.present ? data.position.value : this.position,
      serverNumber: data.serverNumber.present
          ? data.serverNumber.value
          : this.serverNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveMatchPlayer(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('name: $name, ')
          ..write('team: $team, ')
          ..write('isStartingServer: $isStartingServer, ')
          ..write('position: $position, ')
          ..write('serverNumber: $serverNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, matchId, name, team, isStartingServer, position, serverNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveMatchPlayer &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.name == this.name &&
          other.team == this.team &&
          other.isStartingServer == this.isStartingServer &&
          other.position == this.position &&
          other.serverNumber == this.serverNumber);
}

class ActiveMatchPlayersCompanion extends UpdateCompanion<ActiveMatchPlayer> {
  final Value<int> id;
  final Value<int> matchId;
  final Value<String> name;
  final Value<String> team;
  final Value<bool> isStartingServer;
  final Value<String?> position;
  final Value<int?> serverNumber;
  const ActiveMatchPlayersCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.name = const Value.absent(),
    this.team = const Value.absent(),
    this.isStartingServer = const Value.absent(),
    this.position = const Value.absent(),
    this.serverNumber = const Value.absent(),
  });
  ActiveMatchPlayersCompanion.insert({
    this.id = const Value.absent(),
    required int matchId,
    required String name,
    required String team,
    this.isStartingServer = const Value.absent(),
    this.position = const Value.absent(),
    this.serverNumber = const Value.absent(),
  })  : matchId = Value(matchId),
        name = Value(name),
        team = Value(team);
  static Insertable<ActiveMatchPlayer> custom({
    Expression<int>? id,
    Expression<int>? matchId,
    Expression<String>? name,
    Expression<String>? team,
    Expression<bool>? isStartingServer,
    Expression<String>? position,
    Expression<int>? serverNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (name != null) 'name': name,
      if (team != null) 'team': team,
      if (isStartingServer != null) 'is_starting_server': isStartingServer,
      if (position != null) 'position': position,
      if (serverNumber != null) 'server_number': serverNumber,
    });
  }

  ActiveMatchPlayersCompanion copyWith(
      {Value<int>? id,
      Value<int>? matchId,
      Value<String>? name,
      Value<String>? team,
      Value<bool>? isStartingServer,
      Value<String?>? position,
      Value<int?>? serverNumber}) {
    return ActiveMatchPlayersCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      name: name ?? this.name,
      team: team ?? this.team,
      isStartingServer: isStartingServer ?? this.isStartingServer,
      position: position ?? this.position,
      serverNumber: serverNumber ?? this.serverNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<int>(matchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (team.present) {
      map['team'] = Variable<String>(team.value);
    }
    if (isStartingServer.present) {
      map['is_starting_server'] = Variable<bool>(isStartingServer.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (serverNumber.present) {
      map['server_number'] = Variable<int>(serverNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveMatchPlayersCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('name: $name, ')
          ..write('team: $team, ')
          ..write('isStartingServer: $isStartingServer, ')
          ..write('position: $position, ')
          ..write('serverNumber: $serverNumber')
          ..write(')'))
        .toString();
  }
}

class $ScoreEventsTable extends ScoreEvents
    with TableInfo<$ScoreEventsTable, ScoreEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoreEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _matchIdMeta =
      const VerificationMeta('matchId');
  @override
  late final GeneratedColumn<int> matchId = GeneratedColumn<int>(
      'match_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES active_matches (id)'));
  static const VerificationMeta _gameNumberMeta =
      const VerificationMeta('gameNumber');
  @override
  late final GeneratedColumn<int> gameNumber = GeneratedColumn<int>(
      'game_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      check: () =>
          eventType.equals('point') |
          eventType.equals('sideout') |
          eventType.equals('side_switch') |
          eventType.equals('game_end') |
          eventType.equals('match_end'),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _scorerTeamMeta =
      const VerificationMeta('scorerTeam');
  @override
  late final GeneratedColumn<String> scorerTeam = GeneratedColumn<String>(
      'scorer_team', aliasedName, true,
      check: () => scorerTeam.equals('A') | scorerTeam.equals('B'),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _serverNameMeta =
      const VerificationMeta('serverName');
  @override
  late final GeneratedColumn<String> serverName = GeneratedColumn<String>(
      'server_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teamAScoreMeta =
      const VerificationMeta('teamAScore');
  @override
  late final GeneratedColumn<int> teamAScore = GeneratedColumn<int>(
      'team_a_score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _teamBScoreMeta =
      const VerificationMeta('teamBScore');
  @override
  late final GeneratedColumn<int> teamBScore = GeneratedColumn<int>(
      'team_b_score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _serverNumberMeta =
      const VerificationMeta('serverNumber');
  @override
  late final GeneratedColumn<int> serverNumber = GeneratedColumn<int>(
      'server_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        matchId,
        gameNumber,
        eventType,
        scorerTeam,
        serverName,
        teamAScore,
        teamBScore,
        serverNumber,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'score_events';
  @override
  VerificationContext validateIntegrity(Insertable<ScoreEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_id')) {
      context.handle(_matchIdMeta,
          matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta));
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('game_number')) {
      context.handle(
          _gameNumberMeta,
          gameNumber.isAcceptableOrUnknown(
              data['game_number']!, _gameNumberMeta));
    } else if (isInserting) {
      context.missing(_gameNumberMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('scorer_team')) {
      context.handle(
          _scorerTeamMeta,
          scorerTeam.isAcceptableOrUnknown(
              data['scorer_team']!, _scorerTeamMeta));
    }
    if (data.containsKey('server_name')) {
      context.handle(
          _serverNameMeta,
          serverName.isAcceptableOrUnknown(
              data['server_name']!, _serverNameMeta));
    }
    if (data.containsKey('team_a_score')) {
      context.handle(
          _teamAScoreMeta,
          teamAScore.isAcceptableOrUnknown(
              data['team_a_score']!, _teamAScoreMeta));
    } else if (isInserting) {
      context.missing(_teamAScoreMeta);
    }
    if (data.containsKey('team_b_score')) {
      context.handle(
          _teamBScoreMeta,
          teamBScore.isAcceptableOrUnknown(
              data['team_b_score']!, _teamBScoreMeta));
    } else if (isInserting) {
      context.missing(_teamBScoreMeta);
    }
    if (data.containsKey('server_number')) {
      context.handle(
          _serverNumberMeta,
          serverNumber.isAcceptableOrUnknown(
              data['server_number']!, _serverNumberMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoreEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      matchId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}match_id'])!,
      gameNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}game_number'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      scorerTeam: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scorer_team']),
      serverName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_name']),
      teamAScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}team_a_score'])!,
      teamBScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}team_b_score'])!,
      serverNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_number']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $ScoreEventsTable createAlias(String alias) {
    return $ScoreEventsTable(attachedDatabase, alias);
  }
}

class ScoreEvent extends DataClass implements Insertable<ScoreEvent> {
  final int id;
  final int matchId;
  final int gameNumber;
  final String eventType;
  final String? scorerTeam;
  final String? serverName;
  final int teamAScore;
  final int teamBScore;
  final int? serverNumber;
  final DateTime timestamp;
  const ScoreEvent(
      {required this.id,
      required this.matchId,
      required this.gameNumber,
      required this.eventType,
      this.scorerTeam,
      this.serverName,
      required this.teamAScore,
      required this.teamBScore,
      this.serverNumber,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_id'] = Variable<int>(matchId);
    map['game_number'] = Variable<int>(gameNumber);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || scorerTeam != null) {
      map['scorer_team'] = Variable<String>(scorerTeam);
    }
    if (!nullToAbsent || serverName != null) {
      map['server_name'] = Variable<String>(serverName);
    }
    map['team_a_score'] = Variable<int>(teamAScore);
    map['team_b_score'] = Variable<int>(teamBScore);
    if (!nullToAbsent || serverNumber != null) {
      map['server_number'] = Variable<int>(serverNumber);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  ScoreEventsCompanion toCompanion(bool nullToAbsent) {
    return ScoreEventsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      gameNumber: Value(gameNumber),
      eventType: Value(eventType),
      scorerTeam: scorerTeam == null && nullToAbsent
          ? const Value.absent()
          : Value(scorerTeam),
      serverName: serverName == null && nullToAbsent
          ? const Value.absent()
          : Value(serverName),
      teamAScore: Value(teamAScore),
      teamBScore: Value(teamBScore),
      serverNumber: serverNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serverNumber),
      timestamp: Value(timestamp),
    );
  }

  factory ScoreEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreEvent(
      id: serializer.fromJson<int>(json['id']),
      matchId: serializer.fromJson<int>(json['matchId']),
      gameNumber: serializer.fromJson<int>(json['gameNumber']),
      eventType: serializer.fromJson<String>(json['eventType']),
      scorerTeam: serializer.fromJson<String?>(json['scorerTeam']),
      serverName: serializer.fromJson<String?>(json['serverName']),
      teamAScore: serializer.fromJson<int>(json['teamAScore']),
      teamBScore: serializer.fromJson<int>(json['teamBScore']),
      serverNumber: serializer.fromJson<int?>(json['serverNumber']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchId': serializer.toJson<int>(matchId),
      'gameNumber': serializer.toJson<int>(gameNumber),
      'eventType': serializer.toJson<String>(eventType),
      'scorerTeam': serializer.toJson<String?>(scorerTeam),
      'serverName': serializer.toJson<String?>(serverName),
      'teamAScore': serializer.toJson<int>(teamAScore),
      'teamBScore': serializer.toJson<int>(teamBScore),
      'serverNumber': serializer.toJson<int?>(serverNumber),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ScoreEvent copyWith(
          {int? id,
          int? matchId,
          int? gameNumber,
          String? eventType,
          Value<String?> scorerTeam = const Value.absent(),
          Value<String?> serverName = const Value.absent(),
          int? teamAScore,
          int? teamBScore,
          Value<int?> serverNumber = const Value.absent(),
          DateTime? timestamp}) =>
      ScoreEvent(
        id: id ?? this.id,
        matchId: matchId ?? this.matchId,
        gameNumber: gameNumber ?? this.gameNumber,
        eventType: eventType ?? this.eventType,
        scorerTeam: scorerTeam.present ? scorerTeam.value : this.scorerTeam,
        serverName: serverName.present ? serverName.value : this.serverName,
        teamAScore: teamAScore ?? this.teamAScore,
        teamBScore: teamBScore ?? this.teamBScore,
        serverNumber:
            serverNumber.present ? serverNumber.value : this.serverNumber,
        timestamp: timestamp ?? this.timestamp,
      );
  ScoreEvent copyWithCompanion(ScoreEventsCompanion data) {
    return ScoreEvent(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      gameNumber:
          data.gameNumber.present ? data.gameNumber.value : this.gameNumber,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      scorerTeam:
          data.scorerTeam.present ? data.scorerTeam.value : this.scorerTeam,
      serverName:
          data.serverName.present ? data.serverName.value : this.serverName,
      teamAScore:
          data.teamAScore.present ? data.teamAScore.value : this.teamAScore,
      teamBScore:
          data.teamBScore.present ? data.teamBScore.value : this.teamBScore,
      serverNumber: data.serverNumber.present
          ? data.serverNumber.value
          : this.serverNumber,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreEvent(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('gameNumber: $gameNumber, ')
          ..write('eventType: $eventType, ')
          ..write('scorerTeam: $scorerTeam, ')
          ..write('serverName: $serverName, ')
          ..write('teamAScore: $teamAScore, ')
          ..write('teamBScore: $teamBScore, ')
          ..write('serverNumber: $serverNumber, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, matchId, gameNumber, eventType,
      scorerTeam, serverName, teamAScore, teamBScore, serverNumber, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoreEvent &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.gameNumber == this.gameNumber &&
          other.eventType == this.eventType &&
          other.scorerTeam == this.scorerTeam &&
          other.serverName == this.serverName &&
          other.teamAScore == this.teamAScore &&
          other.teamBScore == this.teamBScore &&
          other.serverNumber == this.serverNumber &&
          other.timestamp == this.timestamp);
}

class ScoreEventsCompanion extends UpdateCompanion<ScoreEvent> {
  final Value<int> id;
  final Value<int> matchId;
  final Value<int> gameNumber;
  final Value<String> eventType;
  final Value<String?> scorerTeam;
  final Value<String?> serverName;
  final Value<int> teamAScore;
  final Value<int> teamBScore;
  final Value<int?> serverNumber;
  final Value<DateTime> timestamp;
  const ScoreEventsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.gameNumber = const Value.absent(),
    this.eventType = const Value.absent(),
    this.scorerTeam = const Value.absent(),
    this.serverName = const Value.absent(),
    this.teamAScore = const Value.absent(),
    this.teamBScore = const Value.absent(),
    this.serverNumber = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  ScoreEventsCompanion.insert({
    this.id = const Value.absent(),
    required int matchId,
    required int gameNumber,
    required String eventType,
    this.scorerTeam = const Value.absent(),
    this.serverName = const Value.absent(),
    required int teamAScore,
    required int teamBScore,
    this.serverNumber = const Value.absent(),
    required DateTime timestamp,
  })  : matchId = Value(matchId),
        gameNumber = Value(gameNumber),
        eventType = Value(eventType),
        teamAScore = Value(teamAScore),
        teamBScore = Value(teamBScore),
        timestamp = Value(timestamp);
  static Insertable<ScoreEvent> custom({
    Expression<int>? id,
    Expression<int>? matchId,
    Expression<int>? gameNumber,
    Expression<String>? eventType,
    Expression<String>? scorerTeam,
    Expression<String>? serverName,
    Expression<int>? teamAScore,
    Expression<int>? teamBScore,
    Expression<int>? serverNumber,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (gameNumber != null) 'game_number': gameNumber,
      if (eventType != null) 'event_type': eventType,
      if (scorerTeam != null) 'scorer_team': scorerTeam,
      if (serverName != null) 'server_name': serverName,
      if (teamAScore != null) 'team_a_score': teamAScore,
      if (teamBScore != null) 'team_b_score': teamBScore,
      if (serverNumber != null) 'server_number': serverNumber,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  ScoreEventsCompanion copyWith(
      {Value<int>? id,
      Value<int>? matchId,
      Value<int>? gameNumber,
      Value<String>? eventType,
      Value<String?>? scorerTeam,
      Value<String?>? serverName,
      Value<int>? teamAScore,
      Value<int>? teamBScore,
      Value<int?>? serverNumber,
      Value<DateTime>? timestamp}) {
    return ScoreEventsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      gameNumber: gameNumber ?? this.gameNumber,
      eventType: eventType ?? this.eventType,
      scorerTeam: scorerTeam ?? this.scorerTeam,
      serverName: serverName ?? this.serverName,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      serverNumber: serverNumber ?? this.serverNumber,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<int>(matchId.value);
    }
    if (gameNumber.present) {
      map['game_number'] = Variable<int>(gameNumber.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (scorerTeam.present) {
      map['scorer_team'] = Variable<String>(scorerTeam.value);
    }
    if (serverName.present) {
      map['server_name'] = Variable<String>(serverName.value);
    }
    if (teamAScore.present) {
      map['team_a_score'] = Variable<int>(teamAScore.value);
    }
    if (teamBScore.present) {
      map['team_b_score'] = Variable<int>(teamBScore.value);
    }
    if (serverNumber.present) {
      map['server_number'] = Variable<int>(serverNumber.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoreEventsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('gameNumber: $gameNumber, ')
          ..write('eventType: $eventType, ')
          ..write('scorerTeam: $scorerTeam, ')
          ..write('serverName: $serverName, ')
          ..write('teamAScore: $teamAScore, ')
          ..write('teamBScore: $teamBScore, ')
          ..write('serverNumber: $serverNumber, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $CompletedMatchesTable extends CompletedMatches
    with TableInfo<$CompletedMatchesTable, CompletedMatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedMatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      check: () => type.equals('singles') | type.equals('doubles'),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _scoringRuleMeta =
      const VerificationMeta('scoringRule');
  @override
  late final GeneratedColumn<String> scoringRule = GeneratedColumn<String>(
      'scoring_rule', aliasedName, false,
      check: () => scoringRule.equals('sideout') | scoringRule.equals('rally'),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _gameCountMeta =
      const VerificationMeta('gameCount');
  @override
  late final GeneratedColumn<int> gameCount = GeneratedColumn<int>(
      'game_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _gamesPlayedMeta =
      const VerificationMeta('gamesPlayed');
  @override
  late final GeneratedColumn<int> gamesPlayed = GeneratedColumn<int>(
      'games_played', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _playToMeta = const VerificationMeta('playTo');
  @override
  late final GeneratedColumn<int> playTo = GeneratedColumn<int>(
      'play_to', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _winByMeta = const VerificationMeta('winBy');
  @override
  late final GeneratedColumn<int> winBy = GeneratedColumn<int>(
      'win_by', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _teamAPlayersMeta =
      const VerificationMeta('teamAPlayers');
  @override
  late final GeneratedColumn<String> teamAPlayers = GeneratedColumn<String>(
      'team_a_players', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamBPlayersMeta =
      const VerificationMeta('teamBPlayers');
  @override
  late final GeneratedColumn<String> teamBPlayers = GeneratedColumn<String>(
      'team_b_players', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _finalScoresMeta =
      const VerificationMeta('finalScores');
  @override
  late final GeneratedColumn<String> finalScores = GeneratedColumn<String>(
      'final_scores', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _winnerMeta = const VerificationMeta('winner');
  @override
  late final GeneratedColumn<String> winner = GeneratedColumn<String>(
      'winner', aliasedName, false,
      check: () => winner.equals('A') | winner.equals('B'),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        scoringRule,
        gameCount,
        gamesPlayed,
        playTo,
        winBy,
        teamAPlayers,
        teamBPlayers,
        finalScores,
        winner,
        durationSeconds,
        startedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_matches';
  @override
  VerificationContext validateIntegrity(Insertable<CompletedMatche> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('scoring_rule')) {
      context.handle(
          _scoringRuleMeta,
          scoringRule.isAcceptableOrUnknown(
              data['scoring_rule']!, _scoringRuleMeta));
    } else if (isInserting) {
      context.missing(_scoringRuleMeta);
    }
    if (data.containsKey('game_count')) {
      context.handle(_gameCountMeta,
          gameCount.isAcceptableOrUnknown(data['game_count']!, _gameCountMeta));
    } else if (isInserting) {
      context.missing(_gameCountMeta);
    }
    if (data.containsKey('games_played')) {
      context.handle(
          _gamesPlayedMeta,
          gamesPlayed.isAcceptableOrUnknown(
              data['games_played']!, _gamesPlayedMeta));
    } else if (isInserting) {
      context.missing(_gamesPlayedMeta);
    }
    if (data.containsKey('play_to')) {
      context.handle(_playToMeta,
          playTo.isAcceptableOrUnknown(data['play_to']!, _playToMeta));
    } else if (isInserting) {
      context.missing(_playToMeta);
    }
    if (data.containsKey('win_by')) {
      context.handle(
          _winByMeta, winBy.isAcceptableOrUnknown(data['win_by']!, _winByMeta));
    } else if (isInserting) {
      context.missing(_winByMeta);
    }
    if (data.containsKey('team_a_players')) {
      context.handle(
          _teamAPlayersMeta,
          teamAPlayers.isAcceptableOrUnknown(
              data['team_a_players']!, _teamAPlayersMeta));
    } else if (isInserting) {
      context.missing(_teamAPlayersMeta);
    }
    if (data.containsKey('team_b_players')) {
      context.handle(
          _teamBPlayersMeta,
          teamBPlayers.isAcceptableOrUnknown(
              data['team_b_players']!, _teamBPlayersMeta));
    } else if (isInserting) {
      context.missing(_teamBPlayersMeta);
    }
    if (data.containsKey('final_scores')) {
      context.handle(
          _finalScoresMeta,
          finalScores.isAcceptableOrUnknown(
              data['final_scores']!, _finalScoresMeta));
    } else if (isInserting) {
      context.missing(_finalScoresMeta);
    }
    if (data.containsKey('winner')) {
      context.handle(_winnerMeta,
          winner.isAcceptableOrUnknown(data['winner']!, _winnerMeta));
    } else if (isInserting) {
      context.missing(_winnerMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletedMatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedMatche(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      scoringRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scoring_rule'])!,
      gameCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}game_count'])!,
      gamesPlayed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}games_played'])!,
      playTo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}play_to'])!,
      winBy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}win_by'])!,
      teamAPlayers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_a_players'])!,
      teamBPlayers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_b_players'])!,
      finalScores: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}final_scores'])!,
      winner: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}winner'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
    );
  }

  @override
  $CompletedMatchesTable createAlias(String alias) {
    return $CompletedMatchesTable(attachedDatabase, alias);
  }
}

class CompletedMatche extends DataClass implements Insertable<CompletedMatche> {
  final int id;
  final String type;
  final String scoringRule;
  final int gameCount;
  final int gamesPlayed;
  final int playTo;
  final int winBy;
  final String teamAPlayers;
  final String teamBPlayers;
  final String finalScores;
  final String winner;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;
  const CompletedMatche(
      {required this.id,
      required this.type,
      required this.scoringRule,
      required this.gameCount,
      required this.gamesPlayed,
      required this.playTo,
      required this.winBy,
      required this.teamAPlayers,
      required this.teamBPlayers,
      required this.finalScores,
      required this.winner,
      required this.durationSeconds,
      required this.startedAt,
      required this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['scoring_rule'] = Variable<String>(scoringRule);
    map['game_count'] = Variable<int>(gameCount);
    map['games_played'] = Variable<int>(gamesPlayed);
    map['play_to'] = Variable<int>(playTo);
    map['win_by'] = Variable<int>(winBy);
    map['team_a_players'] = Variable<String>(teamAPlayers);
    map['team_b_players'] = Variable<String>(teamBPlayers);
    map['final_scores'] = Variable<String>(finalScores);
    map['winner'] = Variable<String>(winner);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  CompletedMatchesCompanion toCompanion(bool nullToAbsent) {
    return CompletedMatchesCompanion(
      id: Value(id),
      type: Value(type),
      scoringRule: Value(scoringRule),
      gameCount: Value(gameCount),
      gamesPlayed: Value(gamesPlayed),
      playTo: Value(playTo),
      winBy: Value(winBy),
      teamAPlayers: Value(teamAPlayers),
      teamBPlayers: Value(teamBPlayers),
      finalScores: Value(finalScores),
      winner: Value(winner),
      durationSeconds: Value(durationSeconds),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
    );
  }

  factory CompletedMatche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedMatche(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      scoringRule: serializer.fromJson<String>(json['scoringRule']),
      gameCount: serializer.fromJson<int>(json['gameCount']),
      gamesPlayed: serializer.fromJson<int>(json['gamesPlayed']),
      playTo: serializer.fromJson<int>(json['playTo']),
      winBy: serializer.fromJson<int>(json['winBy']),
      teamAPlayers: serializer.fromJson<String>(json['teamAPlayers']),
      teamBPlayers: serializer.fromJson<String>(json['teamBPlayers']),
      finalScores: serializer.fromJson<String>(json['finalScores']),
      winner: serializer.fromJson<String>(json['winner']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'scoringRule': serializer.toJson<String>(scoringRule),
      'gameCount': serializer.toJson<int>(gameCount),
      'gamesPlayed': serializer.toJson<int>(gamesPlayed),
      'playTo': serializer.toJson<int>(playTo),
      'winBy': serializer.toJson<int>(winBy),
      'teamAPlayers': serializer.toJson<String>(teamAPlayers),
      'teamBPlayers': serializer.toJson<String>(teamBPlayers),
      'finalScores': serializer.toJson<String>(finalScores),
      'winner': serializer.toJson<String>(winner),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  CompletedMatche copyWith(
          {int? id,
          String? type,
          String? scoringRule,
          int? gameCount,
          int? gamesPlayed,
          int? playTo,
          int? winBy,
          String? teamAPlayers,
          String? teamBPlayers,
          String? finalScores,
          String? winner,
          int? durationSeconds,
          DateTime? startedAt,
          DateTime? completedAt}) =>
      CompletedMatche(
        id: id ?? this.id,
        type: type ?? this.type,
        scoringRule: scoringRule ?? this.scoringRule,
        gameCount: gameCount ?? this.gameCount,
        gamesPlayed: gamesPlayed ?? this.gamesPlayed,
        playTo: playTo ?? this.playTo,
        winBy: winBy ?? this.winBy,
        teamAPlayers: teamAPlayers ?? this.teamAPlayers,
        teamBPlayers: teamBPlayers ?? this.teamBPlayers,
        finalScores: finalScores ?? this.finalScores,
        winner: winner ?? this.winner,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
      );
  CompletedMatche copyWithCompanion(CompletedMatchesCompanion data) {
    return CompletedMatche(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      scoringRule:
          data.scoringRule.present ? data.scoringRule.value : this.scoringRule,
      gameCount: data.gameCount.present ? data.gameCount.value : this.gameCount,
      gamesPlayed:
          data.gamesPlayed.present ? data.gamesPlayed.value : this.gamesPlayed,
      playTo: data.playTo.present ? data.playTo.value : this.playTo,
      winBy: data.winBy.present ? data.winBy.value : this.winBy,
      teamAPlayers: data.teamAPlayers.present
          ? data.teamAPlayers.value
          : this.teamAPlayers,
      teamBPlayers: data.teamBPlayers.present
          ? data.teamBPlayers.value
          : this.teamBPlayers,
      finalScores:
          data.finalScores.present ? data.finalScores.value : this.finalScores,
      winner: data.winner.present ? data.winner.value : this.winner,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedMatche(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('scoringRule: $scoringRule, ')
          ..write('gameCount: $gameCount, ')
          ..write('gamesPlayed: $gamesPlayed, ')
          ..write('playTo: $playTo, ')
          ..write('winBy: $winBy, ')
          ..write('teamAPlayers: $teamAPlayers, ')
          ..write('teamBPlayers: $teamBPlayers, ')
          ..write('finalScores: $finalScores, ')
          ..write('winner: $winner, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      scoringRule,
      gameCount,
      gamesPlayed,
      playTo,
      winBy,
      teamAPlayers,
      teamBPlayers,
      finalScores,
      winner,
      durationSeconds,
      startedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedMatche &&
          other.id == this.id &&
          other.type == this.type &&
          other.scoringRule == this.scoringRule &&
          other.gameCount == this.gameCount &&
          other.gamesPlayed == this.gamesPlayed &&
          other.playTo == this.playTo &&
          other.winBy == this.winBy &&
          other.teamAPlayers == this.teamAPlayers &&
          other.teamBPlayers == this.teamBPlayers &&
          other.finalScores == this.finalScores &&
          other.winner == this.winner &&
          other.durationSeconds == this.durationSeconds &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class CompletedMatchesCompanion extends UpdateCompanion<CompletedMatche> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> scoringRule;
  final Value<int> gameCount;
  final Value<int> gamesPlayed;
  final Value<int> playTo;
  final Value<int> winBy;
  final Value<String> teamAPlayers;
  final Value<String> teamBPlayers;
  final Value<String> finalScores;
  final Value<String> winner;
  final Value<int> durationSeconds;
  final Value<DateTime> startedAt;
  final Value<DateTime> completedAt;
  const CompletedMatchesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.scoringRule = const Value.absent(),
    this.gameCount = const Value.absent(),
    this.gamesPlayed = const Value.absent(),
    this.playTo = const Value.absent(),
    this.winBy = const Value.absent(),
    this.teamAPlayers = const Value.absent(),
    this.teamBPlayers = const Value.absent(),
    this.finalScores = const Value.absent(),
    this.winner = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  CompletedMatchesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String scoringRule,
    required int gameCount,
    required int gamesPlayed,
    required int playTo,
    required int winBy,
    required String teamAPlayers,
    required String teamBPlayers,
    required String finalScores,
    required String winner,
    required int durationSeconds,
    required DateTime startedAt,
    required DateTime completedAt,
  })  : type = Value(type),
        scoringRule = Value(scoringRule),
        gameCount = Value(gameCount),
        gamesPlayed = Value(gamesPlayed),
        playTo = Value(playTo),
        winBy = Value(winBy),
        teamAPlayers = Value(teamAPlayers),
        teamBPlayers = Value(teamBPlayers),
        finalScores = Value(finalScores),
        winner = Value(winner),
        durationSeconds = Value(durationSeconds),
        startedAt = Value(startedAt),
        completedAt = Value(completedAt);
  static Insertable<CompletedMatche> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? scoringRule,
    Expression<int>? gameCount,
    Expression<int>? gamesPlayed,
    Expression<int>? playTo,
    Expression<int>? winBy,
    Expression<String>? teamAPlayers,
    Expression<String>? teamBPlayers,
    Expression<String>? finalScores,
    Expression<String>? winner,
    Expression<int>? durationSeconds,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (scoringRule != null) 'scoring_rule': scoringRule,
      if (gameCount != null) 'game_count': gameCount,
      if (gamesPlayed != null) 'games_played': gamesPlayed,
      if (playTo != null) 'play_to': playTo,
      if (winBy != null) 'win_by': winBy,
      if (teamAPlayers != null) 'team_a_players': teamAPlayers,
      if (teamBPlayers != null) 'team_b_players': teamBPlayers,
      if (finalScores != null) 'final_scores': finalScores,
      if (winner != null) 'winner': winner,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  CompletedMatchesCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String>? scoringRule,
      Value<int>? gameCount,
      Value<int>? gamesPlayed,
      Value<int>? playTo,
      Value<int>? winBy,
      Value<String>? teamAPlayers,
      Value<String>? teamBPlayers,
      Value<String>? finalScores,
      Value<String>? winner,
      Value<int>? durationSeconds,
      Value<DateTime>? startedAt,
      Value<DateTime>? completedAt}) {
    return CompletedMatchesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      scoringRule: scoringRule ?? this.scoringRule,
      gameCount: gameCount ?? this.gameCount,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      playTo: playTo ?? this.playTo,
      winBy: winBy ?? this.winBy,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
      finalScores: finalScores ?? this.finalScores,
      winner: winner ?? this.winner,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (scoringRule.present) {
      map['scoring_rule'] = Variable<String>(scoringRule.value);
    }
    if (gameCount.present) {
      map['game_count'] = Variable<int>(gameCount.value);
    }
    if (gamesPlayed.present) {
      map['games_played'] = Variable<int>(gamesPlayed.value);
    }
    if (playTo.present) {
      map['play_to'] = Variable<int>(playTo.value);
    }
    if (winBy.present) {
      map['win_by'] = Variable<int>(winBy.value);
    }
    if (teamAPlayers.present) {
      map['team_a_players'] = Variable<String>(teamAPlayers.value);
    }
    if (teamBPlayers.present) {
      map['team_b_players'] = Variable<String>(teamBPlayers.value);
    }
    if (finalScores.present) {
      map['final_scores'] = Variable<String>(finalScores.value);
    }
    if (winner.present) {
      map['winner'] = Variable<String>(winner.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedMatchesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('scoringRule: $scoringRule, ')
          ..write('gameCount: $gameCount, ')
          ..write('gamesPlayed: $gamesPlayed, ')
          ..write('playTo: $playTo, ')
          ..write('winBy: $winBy, ')
          ..write('teamAPlayers: $teamAPlayers, ')
          ..write('teamBPlayers: $teamBPlayers, ')
          ..write('finalScores: $finalScores, ')
          ..write('winner: $winner, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $MatchEventLogTable extends MatchEventLog
    with TableInfo<$MatchEventLogTable, MatchEventLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchEventLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _completedMatchIdMeta =
      const VerificationMeta('completedMatchId');
  @override
  late final GeneratedColumn<int> completedMatchId = GeneratedColumn<int>(
      'completed_match_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES completed_matches (id)'));
  static const VerificationMeta _gameNumberMeta =
      const VerificationMeta('gameNumber');
  @override
  late final GeneratedColumn<int> gameNumber = GeneratedColumn<int>(
      'game_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scorerTeamMeta =
      const VerificationMeta('scorerTeam');
  @override
  late final GeneratedColumn<String> scorerTeam = GeneratedColumn<String>(
      'scorer_team', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverNameMeta =
      const VerificationMeta('serverName');
  @override
  late final GeneratedColumn<String> serverName = GeneratedColumn<String>(
      'server_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teamAScoreMeta =
      const VerificationMeta('teamAScore');
  @override
  late final GeneratedColumn<int> teamAScore = GeneratedColumn<int>(
      'team_a_score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _teamBScoreMeta =
      const VerificationMeta('teamBScore');
  @override
  late final GeneratedColumn<int> teamBScore = GeneratedColumn<int>(
      'team_b_score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _serverNumberMeta =
      const VerificationMeta('serverNumber');
  @override
  late final GeneratedColumn<int> serverNumber = GeneratedColumn<int>(
      'server_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        completedMatchId,
        gameNumber,
        eventType,
        scorerTeam,
        serverName,
        teamAScore,
        teamBScore,
        serverNumber,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_event_log';
  @override
  VerificationContext validateIntegrity(Insertable<MatchEventLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('completed_match_id')) {
      context.handle(
          _completedMatchIdMeta,
          completedMatchId.isAcceptableOrUnknown(
              data['completed_match_id']!, _completedMatchIdMeta));
    } else if (isInserting) {
      context.missing(_completedMatchIdMeta);
    }
    if (data.containsKey('game_number')) {
      context.handle(
          _gameNumberMeta,
          gameNumber.isAcceptableOrUnknown(
              data['game_number']!, _gameNumberMeta));
    } else if (isInserting) {
      context.missing(_gameNumberMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('scorer_team')) {
      context.handle(
          _scorerTeamMeta,
          scorerTeam.isAcceptableOrUnknown(
              data['scorer_team']!, _scorerTeamMeta));
    }
    if (data.containsKey('server_name')) {
      context.handle(
          _serverNameMeta,
          serverName.isAcceptableOrUnknown(
              data['server_name']!, _serverNameMeta));
    }
    if (data.containsKey('team_a_score')) {
      context.handle(
          _teamAScoreMeta,
          teamAScore.isAcceptableOrUnknown(
              data['team_a_score']!, _teamAScoreMeta));
    } else if (isInserting) {
      context.missing(_teamAScoreMeta);
    }
    if (data.containsKey('team_b_score')) {
      context.handle(
          _teamBScoreMeta,
          teamBScore.isAcceptableOrUnknown(
              data['team_b_score']!, _teamBScoreMeta));
    } else if (isInserting) {
      context.missing(_teamBScoreMeta);
    }
    if (data.containsKey('server_number')) {
      context.handle(
          _serverNumberMeta,
          serverNumber.isAcceptableOrUnknown(
              data['server_number']!, _serverNumberMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MatchEventLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchEventLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      completedMatchId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_match_id'])!,
      gameNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}game_number'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      scorerTeam: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scorer_team']),
      serverName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_name']),
      teamAScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}team_a_score'])!,
      teamBScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}team_b_score'])!,
      serverNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_number']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $MatchEventLogTable createAlias(String alias) {
    return $MatchEventLogTable(attachedDatabase, alias);
  }
}

class MatchEventLogData extends DataClass
    implements Insertable<MatchEventLogData> {
  final int id;
  final int completedMatchId;
  final int gameNumber;
  final String eventType;
  final String? scorerTeam;
  final String? serverName;
  final int teamAScore;
  final int teamBScore;
  final int? serverNumber;
  final DateTime timestamp;
  const MatchEventLogData(
      {required this.id,
      required this.completedMatchId,
      required this.gameNumber,
      required this.eventType,
      this.scorerTeam,
      this.serverName,
      required this.teamAScore,
      required this.teamBScore,
      this.serverNumber,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['completed_match_id'] = Variable<int>(completedMatchId);
    map['game_number'] = Variable<int>(gameNumber);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || scorerTeam != null) {
      map['scorer_team'] = Variable<String>(scorerTeam);
    }
    if (!nullToAbsent || serverName != null) {
      map['server_name'] = Variable<String>(serverName);
    }
    map['team_a_score'] = Variable<int>(teamAScore);
    map['team_b_score'] = Variable<int>(teamBScore);
    if (!nullToAbsent || serverNumber != null) {
      map['server_number'] = Variable<int>(serverNumber);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  MatchEventLogCompanion toCompanion(bool nullToAbsent) {
    return MatchEventLogCompanion(
      id: Value(id),
      completedMatchId: Value(completedMatchId),
      gameNumber: Value(gameNumber),
      eventType: Value(eventType),
      scorerTeam: scorerTeam == null && nullToAbsent
          ? const Value.absent()
          : Value(scorerTeam),
      serverName: serverName == null && nullToAbsent
          ? const Value.absent()
          : Value(serverName),
      teamAScore: Value(teamAScore),
      teamBScore: Value(teamBScore),
      serverNumber: serverNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serverNumber),
      timestamp: Value(timestamp),
    );
  }

  factory MatchEventLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchEventLogData(
      id: serializer.fromJson<int>(json['id']),
      completedMatchId: serializer.fromJson<int>(json['completedMatchId']),
      gameNumber: serializer.fromJson<int>(json['gameNumber']),
      eventType: serializer.fromJson<String>(json['eventType']),
      scorerTeam: serializer.fromJson<String?>(json['scorerTeam']),
      serverName: serializer.fromJson<String?>(json['serverName']),
      teamAScore: serializer.fromJson<int>(json['teamAScore']),
      teamBScore: serializer.fromJson<int>(json['teamBScore']),
      serverNumber: serializer.fromJson<int?>(json['serverNumber']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'completedMatchId': serializer.toJson<int>(completedMatchId),
      'gameNumber': serializer.toJson<int>(gameNumber),
      'eventType': serializer.toJson<String>(eventType),
      'scorerTeam': serializer.toJson<String?>(scorerTeam),
      'serverName': serializer.toJson<String?>(serverName),
      'teamAScore': serializer.toJson<int>(teamAScore),
      'teamBScore': serializer.toJson<int>(teamBScore),
      'serverNumber': serializer.toJson<int?>(serverNumber),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  MatchEventLogData copyWith(
          {int? id,
          int? completedMatchId,
          int? gameNumber,
          String? eventType,
          Value<String?> scorerTeam = const Value.absent(),
          Value<String?> serverName = const Value.absent(),
          int? teamAScore,
          int? teamBScore,
          Value<int?> serverNumber = const Value.absent(),
          DateTime? timestamp}) =>
      MatchEventLogData(
        id: id ?? this.id,
        completedMatchId: completedMatchId ?? this.completedMatchId,
        gameNumber: gameNumber ?? this.gameNumber,
        eventType: eventType ?? this.eventType,
        scorerTeam: scorerTeam.present ? scorerTeam.value : this.scorerTeam,
        serverName: serverName.present ? serverName.value : this.serverName,
        teamAScore: teamAScore ?? this.teamAScore,
        teamBScore: teamBScore ?? this.teamBScore,
        serverNumber:
            serverNumber.present ? serverNumber.value : this.serverNumber,
        timestamp: timestamp ?? this.timestamp,
      );
  MatchEventLogData copyWithCompanion(MatchEventLogCompanion data) {
    return MatchEventLogData(
      id: data.id.present ? data.id.value : this.id,
      completedMatchId: data.completedMatchId.present
          ? data.completedMatchId.value
          : this.completedMatchId,
      gameNumber:
          data.gameNumber.present ? data.gameNumber.value : this.gameNumber,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      scorerTeam:
          data.scorerTeam.present ? data.scorerTeam.value : this.scorerTeam,
      serverName:
          data.serverName.present ? data.serverName.value : this.serverName,
      teamAScore:
          data.teamAScore.present ? data.teamAScore.value : this.teamAScore,
      teamBScore:
          data.teamBScore.present ? data.teamBScore.value : this.teamBScore,
      serverNumber: data.serverNumber.present
          ? data.serverNumber.value
          : this.serverNumber,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchEventLogData(')
          ..write('id: $id, ')
          ..write('completedMatchId: $completedMatchId, ')
          ..write('gameNumber: $gameNumber, ')
          ..write('eventType: $eventType, ')
          ..write('scorerTeam: $scorerTeam, ')
          ..write('serverName: $serverName, ')
          ..write('teamAScore: $teamAScore, ')
          ..write('teamBScore: $teamBScore, ')
          ..write('serverNumber: $serverNumber, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, completedMatchId, gameNumber, eventType,
      scorerTeam, serverName, teamAScore, teamBScore, serverNumber, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchEventLogData &&
          other.id == this.id &&
          other.completedMatchId == this.completedMatchId &&
          other.gameNumber == this.gameNumber &&
          other.eventType == this.eventType &&
          other.scorerTeam == this.scorerTeam &&
          other.serverName == this.serverName &&
          other.teamAScore == this.teamAScore &&
          other.teamBScore == this.teamBScore &&
          other.serverNumber == this.serverNumber &&
          other.timestamp == this.timestamp);
}

class MatchEventLogCompanion extends UpdateCompanion<MatchEventLogData> {
  final Value<int> id;
  final Value<int> completedMatchId;
  final Value<int> gameNumber;
  final Value<String> eventType;
  final Value<String?> scorerTeam;
  final Value<String?> serverName;
  final Value<int> teamAScore;
  final Value<int> teamBScore;
  final Value<int?> serverNumber;
  final Value<DateTime> timestamp;
  const MatchEventLogCompanion({
    this.id = const Value.absent(),
    this.completedMatchId = const Value.absent(),
    this.gameNumber = const Value.absent(),
    this.eventType = const Value.absent(),
    this.scorerTeam = const Value.absent(),
    this.serverName = const Value.absent(),
    this.teamAScore = const Value.absent(),
    this.teamBScore = const Value.absent(),
    this.serverNumber = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  MatchEventLogCompanion.insert({
    this.id = const Value.absent(),
    required int completedMatchId,
    required int gameNumber,
    required String eventType,
    this.scorerTeam = const Value.absent(),
    this.serverName = const Value.absent(),
    required int teamAScore,
    required int teamBScore,
    this.serverNumber = const Value.absent(),
    required DateTime timestamp,
  })  : completedMatchId = Value(completedMatchId),
        gameNumber = Value(gameNumber),
        eventType = Value(eventType),
        teamAScore = Value(teamAScore),
        teamBScore = Value(teamBScore),
        timestamp = Value(timestamp);
  static Insertable<MatchEventLogData> custom({
    Expression<int>? id,
    Expression<int>? completedMatchId,
    Expression<int>? gameNumber,
    Expression<String>? eventType,
    Expression<String>? scorerTeam,
    Expression<String>? serverName,
    Expression<int>? teamAScore,
    Expression<int>? teamBScore,
    Expression<int>? serverNumber,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completedMatchId != null) 'completed_match_id': completedMatchId,
      if (gameNumber != null) 'game_number': gameNumber,
      if (eventType != null) 'event_type': eventType,
      if (scorerTeam != null) 'scorer_team': scorerTeam,
      if (serverName != null) 'server_name': serverName,
      if (teamAScore != null) 'team_a_score': teamAScore,
      if (teamBScore != null) 'team_b_score': teamBScore,
      if (serverNumber != null) 'server_number': serverNumber,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  MatchEventLogCompanion copyWith(
      {Value<int>? id,
      Value<int>? completedMatchId,
      Value<int>? gameNumber,
      Value<String>? eventType,
      Value<String?>? scorerTeam,
      Value<String?>? serverName,
      Value<int>? teamAScore,
      Value<int>? teamBScore,
      Value<int?>? serverNumber,
      Value<DateTime>? timestamp}) {
    return MatchEventLogCompanion(
      id: id ?? this.id,
      completedMatchId: completedMatchId ?? this.completedMatchId,
      gameNumber: gameNumber ?? this.gameNumber,
      eventType: eventType ?? this.eventType,
      scorerTeam: scorerTeam ?? this.scorerTeam,
      serverName: serverName ?? this.serverName,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      serverNumber: serverNumber ?? this.serverNumber,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (completedMatchId.present) {
      map['completed_match_id'] = Variable<int>(completedMatchId.value);
    }
    if (gameNumber.present) {
      map['game_number'] = Variable<int>(gameNumber.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (scorerTeam.present) {
      map['scorer_team'] = Variable<String>(scorerTeam.value);
    }
    if (serverName.present) {
      map['server_name'] = Variable<String>(serverName.value);
    }
    if (teamAScore.present) {
      map['team_a_score'] = Variable<int>(teamAScore.value);
    }
    if (teamBScore.present) {
      map['team_b_score'] = Variable<int>(teamBScore.value);
    }
    if (serverNumber.present) {
      map['server_number'] = Variable<int>(serverNumber.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchEventLogCompanion(')
          ..write('id: $id, ')
          ..write('completedMatchId: $completedMatchId, ')
          ..write('gameNumber: $gameNumber, ')
          ..write('eventType: $eventType, ')
          ..write('scorerTeam: $scorerTeam, ')
          ..write('serverName: $serverName, ')
          ..write('teamAScore: $teamAScore, ')
          ..write('teamBScore: $teamBScore, ')
          ..write('serverNumber: $serverNumber, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $RecentPlayersTable extends RecentPlayers
    with TableInfo<$RecentPlayersTable, RecentPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastUsedMeta =
      const VerificationMeta('lastUsed');
  @override
  late final GeneratedColumn<DateTime> lastUsed = GeneratedColumn<DateTime>(
      'last_used', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _usageCountMeta =
      const VerificationMeta('usageCount');
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
      'usage_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [name, lastUsed, usageCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_players';
  @override
  VerificationContext validateIntegrity(Insertable<RecentPlayer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('last_used')) {
      context.handle(_lastUsedMeta,
          lastUsed.isAcceptableOrUnknown(data['last_used']!, _lastUsedMeta));
    } else if (isInserting) {
      context.missing(_lastUsedMeta);
    }
    if (data.containsKey('usage_count')) {
      context.handle(
          _usageCountMeta,
          usageCount.isAcceptableOrUnknown(
              data['usage_count']!, _usageCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  RecentPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentPlayer(
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      lastUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used'])!,
      usageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usage_count'])!,
    );
  }

  @override
  $RecentPlayersTable createAlias(String alias) {
    return $RecentPlayersTable(attachedDatabase, alias);
  }
}

class RecentPlayer extends DataClass implements Insertable<RecentPlayer> {
  final String name;
  final DateTime lastUsed;
  final int usageCount;
  const RecentPlayer(
      {required this.name, required this.lastUsed, required this.usageCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['last_used'] = Variable<DateTime>(lastUsed);
    map['usage_count'] = Variable<int>(usageCount);
    return map;
  }

  RecentPlayersCompanion toCompanion(bool nullToAbsent) {
    return RecentPlayersCompanion(
      name: Value(name),
      lastUsed: Value(lastUsed),
      usageCount: Value(usageCount),
    );
  }

  factory RecentPlayer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentPlayer(
      name: serializer.fromJson<String>(json['name']),
      lastUsed: serializer.fromJson<DateTime>(json['lastUsed']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'lastUsed': serializer.toJson<DateTime>(lastUsed),
      'usageCount': serializer.toJson<int>(usageCount),
    };
  }

  RecentPlayer copyWith({String? name, DateTime? lastUsed, int? usageCount}) =>
      RecentPlayer(
        name: name ?? this.name,
        lastUsed: lastUsed ?? this.lastUsed,
        usageCount: usageCount ?? this.usageCount,
      );
  RecentPlayer copyWithCompanion(RecentPlayersCompanion data) {
    return RecentPlayer(
      name: data.name.present ? data.name.value : this.name,
      lastUsed: data.lastUsed.present ? data.lastUsed.value : this.lastUsed,
      usageCount:
          data.usageCount.present ? data.usageCount.value : this.usageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentPlayer(')
          ..write('name: $name, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('usageCount: $usageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, lastUsed, usageCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentPlayer &&
          other.name == this.name &&
          other.lastUsed == this.lastUsed &&
          other.usageCount == this.usageCount);
}

class RecentPlayersCompanion extends UpdateCompanion<RecentPlayer> {
  final Value<String> name;
  final Value<DateTime> lastUsed;
  final Value<int> usageCount;
  final Value<int> rowid;
  const RecentPlayersCompanion({
    this.name = const Value.absent(),
    this.lastUsed = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentPlayersCompanion.insert({
    required String name,
    required DateTime lastUsed,
    this.usageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        lastUsed = Value(lastUsed);
  static Insertable<RecentPlayer> custom({
    Expression<String>? name,
    Expression<DateTime>? lastUsed,
    Expression<int>? usageCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (lastUsed != null) 'last_used': lastUsed,
      if (usageCount != null) 'usage_count': usageCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentPlayersCompanion copyWith(
      {Value<String>? name,
      Value<DateTime>? lastUsed,
      Value<int>? usageCount,
      Value<int>? rowid}) {
    return RecentPlayersCompanion(
      name: name ?? this.name,
      lastUsed: lastUsed ?? this.lastUsed,
      usageCount: usageCount ?? this.usageCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastUsed.present) {
      map['last_used'] = Variable<DateTime>(lastUsed.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentPlayersCompanion(')
          ..write('name: $name, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('usageCount: $usageCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) => AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ActiveMatchesTable activeMatches = $ActiveMatchesTable(this);
  late final $ActiveMatchPlayersTable activeMatchPlayers =
      $ActiveMatchPlayersTable(this);
  late final $ScoreEventsTable scoreEvents = $ScoreEventsTable(this);
  late final $CompletedMatchesTable completedMatches =
      $CompletedMatchesTable(this);
  late final $MatchEventLogTable matchEventLog = $MatchEventLogTable(this);
  late final $RecentPlayersTable recentPlayers = $RecentPlayersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        activeMatches,
        activeMatchPlayers,
        scoreEvents,
        completedMatches,
        matchEventLog,
        recentPlayers,
        appSettings
      ];
}

typedef $$ActiveMatchesTableCreateCompanionBuilder = ActiveMatchesCompanion
    Function({
  Value<int> id,
  required String type,
  required String scoringRule,
  Value<int> gameCount,
  Value<int> playTo,
  Value<int> winBy,
  required DateTime createdAt,
  Value<String> status,
});
typedef $$ActiveMatchesTableUpdateCompanionBuilder = ActiveMatchesCompanion
    Function({
  Value<int> id,
  Value<String> type,
  Value<String> scoringRule,
  Value<int> gameCount,
  Value<int> playTo,
  Value<int> winBy,
  Value<DateTime> createdAt,
  Value<String> status,
});

final class $$ActiveMatchesTableReferences
    extends BaseReferences<_$AppDatabase, $ActiveMatchesTable, ActiveMatche> {
  $$ActiveMatchesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ActiveMatchPlayersTable, List<ActiveMatchPlayer>>
      _activeMatchPlayersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.activeMatchPlayers,
              aliasName: $_aliasNameGenerator(
                  db.activeMatches.id, db.activeMatchPlayers.matchId));

  $$ActiveMatchPlayersTableProcessedTableManager get activeMatchPlayersRefs {
    final manager =
        $$ActiveMatchPlayersTableTableManager($_db, $_db.activeMatchPlayers)
            .filter((f) => f.matchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_activeMatchPlayersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ScoreEventsTable, List<ScoreEvent>>
      _scoreEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.scoreEvents,
              aliasName: $_aliasNameGenerator(
                  db.activeMatches.id, db.scoreEvents.matchId));

  $$ScoreEventsTableProcessedTableManager get scoreEventsRefs {
    final manager = $$ScoreEventsTableTableManager($_db, $_db.scoreEvents)
        .filter((f) => f.matchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scoreEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ActiveMatchesTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveMatchesTable> {
  $$ActiveMatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scoringRule => $composableBuilder(
      column: $table.scoringRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gameCount => $composableBuilder(
      column: $table.gameCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playTo => $composableBuilder(
      column: $table.playTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get winBy => $composableBuilder(
      column: $table.winBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  Expression<bool> activeMatchPlayersRefs(
      Expression<bool> Function($$ActiveMatchPlayersTableFilterComposer f) f) {
    final $$ActiveMatchPlayersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.activeMatchPlayers,
        getReferencedColumn: (t) => t.matchId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActiveMatchPlayersTableFilterComposer(
              $db: $db,
              $table: $db.activeMatchPlayers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> scoreEventsRefs(
      Expression<bool> Function($$ScoreEventsTableFilterComposer f) f) {
    final $$ScoreEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scoreEvents,
        getReferencedColumn: (t) => t.matchId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScoreEventsTableFilterComposer(
              $db: $db,
              $table: $db.scoreEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ActiveMatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveMatchesTable> {
  $$ActiveMatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scoringRule => $composableBuilder(
      column: $table.scoringRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gameCount => $composableBuilder(
      column: $table.gameCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playTo => $composableBuilder(
      column: $table.playTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get winBy => $composableBuilder(
      column: $table.winBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$ActiveMatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveMatchesTable> {
  $$ActiveMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get scoringRule => $composableBuilder(
      column: $table.scoringRule, builder: (column) => column);

  GeneratedColumn<int> get gameCount =>
      $composableBuilder(column: $table.gameCount, builder: (column) => column);

  GeneratedColumn<int> get playTo =>
      $composableBuilder(column: $table.playTo, builder: (column) => column);

  GeneratedColumn<int> get winBy =>
      $composableBuilder(column: $table.winBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> activeMatchPlayersRefs<T extends Object>(
      Expression<T> Function($$ActiveMatchPlayersTableAnnotationComposer a) f) {
    final $$ActiveMatchPlayersTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.activeMatchPlayers,
            getReferencedColumn: (t) => t.matchId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ActiveMatchPlayersTableAnnotationComposer(
                  $db: $db,
                  $table: $db.activeMatchPlayers,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> scoreEventsRefs<T extends Object>(
      Expression<T> Function($$ScoreEventsTableAnnotationComposer a) f) {
    final $$ScoreEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.scoreEvents,
        getReferencedColumn: (t) => t.matchId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ScoreEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.scoreEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ActiveMatchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActiveMatchesTable,
    ActiveMatche,
    $$ActiveMatchesTableFilterComposer,
    $$ActiveMatchesTableOrderingComposer,
    $$ActiveMatchesTableAnnotationComposer,
    $$ActiveMatchesTableCreateCompanionBuilder,
    $$ActiveMatchesTableUpdateCompanionBuilder,
    (ActiveMatche, $$ActiveMatchesTableReferences),
    ActiveMatche,
    PrefetchHooks Function(
        {bool activeMatchPlayersRefs, bool scoreEventsRefs})> {
  $$ActiveMatchesTableTableManager(_$AppDatabase db, $ActiveMatchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveMatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveMatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> scoringRule = const Value.absent(),
            Value<int> gameCount = const Value.absent(),
            Value<int> playTo = const Value.absent(),
            Value<int> winBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              ActiveMatchesCompanion(
            id: id,
            type: type,
            scoringRule: scoringRule,
            gameCount: gameCount,
            playTo: playTo,
            winBy: winBy,
            createdAt: createdAt,
            status: status,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required String scoringRule,
            Value<int> gameCount = const Value.absent(),
            Value<int> playTo = const Value.absent(),
            Value<int> winBy = const Value.absent(),
            required DateTime createdAt,
            Value<String> status = const Value.absent(),
          }) =>
              ActiveMatchesCompanion.insert(
            id: id,
            type: type,
            scoringRule: scoringRule,
            gameCount: gameCount,
            playTo: playTo,
            winBy: winBy,
            createdAt: createdAt,
            status: status,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ActiveMatchesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {activeMatchPlayersRefs = false, scoreEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (activeMatchPlayersRefs) db.activeMatchPlayers,
                if (scoreEventsRefs) db.scoreEvents
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (activeMatchPlayersRefs)
                    await $_getPrefetchedData<ActiveMatche, $ActiveMatchesTable,
                            ActiveMatchPlayer>(
                        currentTable: table,
                        referencedTable: $$ActiveMatchesTableReferences
                            ._activeMatchPlayersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ActiveMatchesTableReferences(db, table, p0)
                                .activeMatchPlayersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.matchId == item.id),
                        typedResults: items),
                  if (scoreEventsRefs)
                    await $_getPrefetchedData<ActiveMatche, $ActiveMatchesTable,
                            ScoreEvent>(
                        currentTable: table,
                        referencedTable: $$ActiveMatchesTableReferences
                            ._scoreEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ActiveMatchesTableReferences(db, table, p0)
                                .scoreEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.matchId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ActiveMatchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActiveMatchesTable,
    ActiveMatche,
    $$ActiveMatchesTableFilterComposer,
    $$ActiveMatchesTableOrderingComposer,
    $$ActiveMatchesTableAnnotationComposer,
    $$ActiveMatchesTableCreateCompanionBuilder,
    $$ActiveMatchesTableUpdateCompanionBuilder,
    (ActiveMatche, $$ActiveMatchesTableReferences),
    ActiveMatche,
    PrefetchHooks Function(
        {bool activeMatchPlayersRefs, bool scoreEventsRefs})>;
typedef $$ActiveMatchPlayersTableCreateCompanionBuilder
    = ActiveMatchPlayersCompanion Function({
  Value<int> id,
  required int matchId,
  required String name,
  required String team,
  Value<bool> isStartingServer,
  Value<String?> position,
  Value<int?> serverNumber,
});
typedef $$ActiveMatchPlayersTableUpdateCompanionBuilder
    = ActiveMatchPlayersCompanion Function({
  Value<int> id,
  Value<int> matchId,
  Value<String> name,
  Value<String> team,
  Value<bool> isStartingServer,
  Value<String?> position,
  Value<int?> serverNumber,
});

final class $$ActiveMatchPlayersTableReferences extends BaseReferences<
    _$AppDatabase, $ActiveMatchPlayersTable, ActiveMatchPlayer> {
  $$ActiveMatchPlayersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ActiveMatchesTable _matchIdTable(_$AppDatabase db) =>
      db.activeMatches.createAlias($_aliasNameGenerator(
          db.activeMatchPlayers.matchId, db.activeMatches.id));

  $$ActiveMatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<int>('match_id')!;

    final manager = $$ActiveMatchesTableTableManager($_db, $_db.activeMatches)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ActiveMatchPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveMatchPlayersTable> {
  $$ActiveMatchPlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get team => $composableBuilder(
      column: $table.team, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStartingServer => $composableBuilder(
      column: $table.isStartingServer,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber, builder: (column) => ColumnFilters(column));

  $$ActiveMatchesTableFilterComposer get matchId {
    final $$ActiveMatchesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.matchId,
        referencedTable: $db.activeMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActiveMatchesTableFilterComposer(
              $db: $db,
              $table: $db.activeMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActiveMatchPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveMatchPlayersTable> {
  $$ActiveMatchPlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get team => $composableBuilder(
      column: $table.team, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStartingServer => $composableBuilder(
      column: $table.isStartingServer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber,
      builder: (column) => ColumnOrderings(column));

  $$ActiveMatchesTableOrderingComposer get matchId {
    final $$ActiveMatchesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.matchId,
        referencedTable: $db.activeMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActiveMatchesTableOrderingComposer(
              $db: $db,
              $table: $db.activeMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActiveMatchPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveMatchPlayersTable> {
  $$ActiveMatchPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get team =>
      $composableBuilder(column: $table.team, builder: (column) => column);

  GeneratedColumn<bool> get isStartingServer => $composableBuilder(
      column: $table.isStartingServer, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber, builder: (column) => column);

  $$ActiveMatchesTableAnnotationComposer get matchId {
    final $$ActiveMatchesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.matchId,
        referencedTable: $db.activeMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActiveMatchesTableAnnotationComposer(
              $db: $db,
              $table: $db.activeMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActiveMatchPlayersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActiveMatchPlayersTable,
    ActiveMatchPlayer,
    $$ActiveMatchPlayersTableFilterComposer,
    $$ActiveMatchPlayersTableOrderingComposer,
    $$ActiveMatchPlayersTableAnnotationComposer,
    $$ActiveMatchPlayersTableCreateCompanionBuilder,
    $$ActiveMatchPlayersTableUpdateCompanionBuilder,
    (ActiveMatchPlayer, $$ActiveMatchPlayersTableReferences),
    ActiveMatchPlayer,
    PrefetchHooks Function({bool matchId})> {
  $$ActiveMatchPlayersTableTableManager(
      _$AppDatabase db, $ActiveMatchPlayersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveMatchPlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveMatchPlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveMatchPlayersTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> matchId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> team = const Value.absent(),
            Value<bool> isStartingServer = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<int?> serverNumber = const Value.absent(),
          }) =>
              ActiveMatchPlayersCompanion(
            id: id,
            matchId: matchId,
            name: name,
            team: team,
            isStartingServer: isStartingServer,
            position: position,
            serverNumber: serverNumber,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int matchId,
            required String name,
            required String team,
            Value<bool> isStartingServer = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<int?> serverNumber = const Value.absent(),
          }) =>
              ActiveMatchPlayersCompanion.insert(
            id: id,
            matchId: matchId,
            name: name,
            team: team,
            isStartingServer: isStartingServer,
            position: position,
            serverNumber: serverNumber,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ActiveMatchPlayersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({matchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (matchId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.matchId,
                    referencedTable:
                        $$ActiveMatchPlayersTableReferences._matchIdTable(db),
                    referencedColumn: $$ActiveMatchPlayersTableReferences
                        ._matchIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ActiveMatchPlayersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActiveMatchPlayersTable,
    ActiveMatchPlayer,
    $$ActiveMatchPlayersTableFilterComposer,
    $$ActiveMatchPlayersTableOrderingComposer,
    $$ActiveMatchPlayersTableAnnotationComposer,
    $$ActiveMatchPlayersTableCreateCompanionBuilder,
    $$ActiveMatchPlayersTableUpdateCompanionBuilder,
    (ActiveMatchPlayer, $$ActiveMatchPlayersTableReferences),
    ActiveMatchPlayer,
    PrefetchHooks Function({bool matchId})>;
typedef $$ScoreEventsTableCreateCompanionBuilder = ScoreEventsCompanion
    Function({
  Value<int> id,
  required int matchId,
  required int gameNumber,
  required String eventType,
  Value<String?> scorerTeam,
  Value<String?> serverName,
  required int teamAScore,
  required int teamBScore,
  Value<int?> serverNumber,
  required DateTime timestamp,
});
typedef $$ScoreEventsTableUpdateCompanionBuilder = ScoreEventsCompanion
    Function({
  Value<int> id,
  Value<int> matchId,
  Value<int> gameNumber,
  Value<String> eventType,
  Value<String?> scorerTeam,
  Value<String?> serverName,
  Value<int> teamAScore,
  Value<int> teamBScore,
  Value<int?> serverNumber,
  Value<DateTime> timestamp,
});

final class $$ScoreEventsTableReferences
    extends BaseReferences<_$AppDatabase, $ScoreEventsTable, ScoreEvent> {
  $$ScoreEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActiveMatchesTable _matchIdTable(_$AppDatabase db) =>
      db.activeMatches.createAlias(
          $_aliasNameGenerator(db.scoreEvents.matchId, db.activeMatches.id));

  $$ActiveMatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<int>('match_id')!;

    final manager = $$ActiveMatchesTableTableManager($_db, $_db.activeMatches)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ScoreEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ScoreEventsTable> {
  $$ScoreEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gameNumber => $composableBuilder(
      column: $table.gameNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scorerTeam => $composableBuilder(
      column: $table.scorerTeam, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverName => $composableBuilder(
      column: $table.serverName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get teamAScore => $composableBuilder(
      column: $table.teamAScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get teamBScore => $composableBuilder(
      column: $table.teamBScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  $$ActiveMatchesTableFilterComposer get matchId {
    final $$ActiveMatchesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.matchId,
        referencedTable: $db.activeMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActiveMatchesTableFilterComposer(
              $db: $db,
              $table: $db.activeMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScoreEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoreEventsTable> {
  $$ScoreEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gameNumber => $composableBuilder(
      column: $table.gameNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scorerTeam => $composableBuilder(
      column: $table.scorerTeam, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverName => $composableBuilder(
      column: $table.serverName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get teamAScore => $composableBuilder(
      column: $table.teamAScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get teamBScore => $composableBuilder(
      column: $table.teamBScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  $$ActiveMatchesTableOrderingComposer get matchId {
    final $$ActiveMatchesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.matchId,
        referencedTable: $db.activeMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActiveMatchesTableOrderingComposer(
              $db: $db,
              $table: $db.activeMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScoreEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoreEventsTable> {
  $$ScoreEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get gameNumber => $composableBuilder(
      column: $table.gameNumber, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get scorerTeam => $composableBuilder(
      column: $table.scorerTeam, builder: (column) => column);

  GeneratedColumn<String> get serverName => $composableBuilder(
      column: $table.serverName, builder: (column) => column);

  GeneratedColumn<int> get teamAScore => $composableBuilder(
      column: $table.teamAScore, builder: (column) => column);

  GeneratedColumn<int> get teamBScore => $composableBuilder(
      column: $table.teamBScore, builder: (column) => column);

  GeneratedColumn<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$ActiveMatchesTableAnnotationComposer get matchId {
    final $$ActiveMatchesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.matchId,
        referencedTable: $db.activeMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActiveMatchesTableAnnotationComposer(
              $db: $db,
              $table: $db.activeMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ScoreEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScoreEventsTable,
    ScoreEvent,
    $$ScoreEventsTableFilterComposer,
    $$ScoreEventsTableOrderingComposer,
    $$ScoreEventsTableAnnotationComposer,
    $$ScoreEventsTableCreateCompanionBuilder,
    $$ScoreEventsTableUpdateCompanionBuilder,
    (ScoreEvent, $$ScoreEventsTableReferences),
    ScoreEvent,
    PrefetchHooks Function({bool matchId})> {
  $$ScoreEventsTableTableManager(_$AppDatabase db, $ScoreEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoreEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoreEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoreEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> matchId = const Value.absent(),
            Value<int> gameNumber = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String?> scorerTeam = const Value.absent(),
            Value<String?> serverName = const Value.absent(),
            Value<int> teamAScore = const Value.absent(),
            Value<int> teamBScore = const Value.absent(),
            Value<int?> serverNumber = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              ScoreEventsCompanion(
            id: id,
            matchId: matchId,
            gameNumber: gameNumber,
            eventType: eventType,
            scorerTeam: scorerTeam,
            serverName: serverName,
            teamAScore: teamAScore,
            teamBScore: teamBScore,
            serverNumber: serverNumber,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int matchId,
            required int gameNumber,
            required String eventType,
            Value<String?> scorerTeam = const Value.absent(),
            Value<String?> serverName = const Value.absent(),
            required int teamAScore,
            required int teamBScore,
            Value<int?> serverNumber = const Value.absent(),
            required DateTime timestamp,
          }) =>
              ScoreEventsCompanion.insert(
            id: id,
            matchId: matchId,
            gameNumber: gameNumber,
            eventType: eventType,
            scorerTeam: scorerTeam,
            serverName: serverName,
            teamAScore: teamAScore,
            teamBScore: teamBScore,
            serverNumber: serverNumber,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ScoreEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({matchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (matchId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.matchId,
                    referencedTable:
                        $$ScoreEventsTableReferences._matchIdTable(db),
                    referencedColumn:
                        $$ScoreEventsTableReferences._matchIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ScoreEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScoreEventsTable,
    ScoreEvent,
    $$ScoreEventsTableFilterComposer,
    $$ScoreEventsTableOrderingComposer,
    $$ScoreEventsTableAnnotationComposer,
    $$ScoreEventsTableCreateCompanionBuilder,
    $$ScoreEventsTableUpdateCompanionBuilder,
    (ScoreEvent, $$ScoreEventsTableReferences),
    ScoreEvent,
    PrefetchHooks Function({bool matchId})>;
typedef $$CompletedMatchesTableCreateCompanionBuilder
    = CompletedMatchesCompanion Function({
  Value<int> id,
  required String type,
  required String scoringRule,
  required int gameCount,
  required int gamesPlayed,
  required int playTo,
  required int winBy,
  required String teamAPlayers,
  required String teamBPlayers,
  required String finalScores,
  required String winner,
  required int durationSeconds,
  required DateTime startedAt,
  required DateTime completedAt,
});
typedef $$CompletedMatchesTableUpdateCompanionBuilder
    = CompletedMatchesCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<String> scoringRule,
  Value<int> gameCount,
  Value<int> gamesPlayed,
  Value<int> playTo,
  Value<int> winBy,
  Value<String> teamAPlayers,
  Value<String> teamBPlayers,
  Value<String> finalScores,
  Value<String> winner,
  Value<int> durationSeconds,
  Value<DateTime> startedAt,
  Value<DateTime> completedAt,
});

final class $$CompletedMatchesTableReferences extends BaseReferences<
    _$AppDatabase, $CompletedMatchesTable, CompletedMatche> {
  $$CompletedMatchesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MatchEventLogTable, List<MatchEventLogData>>
      _matchEventLogRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.matchEventLog,
              aliasName: $_aliasNameGenerator(
                  db.completedMatches.id, db.matchEventLog.completedMatchId));

  $$MatchEventLogTableProcessedTableManager get matchEventLogRefs {
    final manager = $$MatchEventLogTableTableManager($_db, $_db.matchEventLog)
        .filter(
            (f) => f.completedMatchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_matchEventLogRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CompletedMatchesTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedMatchesTable> {
  $$CompletedMatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scoringRule => $composableBuilder(
      column: $table.scoringRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gameCount => $composableBuilder(
      column: $table.gameCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gamesPlayed => $composableBuilder(
      column: $table.gamesPlayed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playTo => $composableBuilder(
      column: $table.playTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get winBy => $composableBuilder(
      column: $table.winBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamAPlayers => $composableBuilder(
      column: $table.teamAPlayers, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamBPlayers => $composableBuilder(
      column: $table.teamBPlayers, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get finalScores => $composableBuilder(
      column: $table.finalScores, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get winner => $composableBuilder(
      column: $table.winner, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> matchEventLogRefs(
      Expression<bool> Function($$MatchEventLogTableFilterComposer f) f) {
    final $$MatchEventLogTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.matchEventLog,
        getReferencedColumn: (t) => t.completedMatchId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MatchEventLogTableFilterComposer(
              $db: $db,
              $table: $db.matchEventLog,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CompletedMatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedMatchesTable> {
  $$CompletedMatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scoringRule => $composableBuilder(
      column: $table.scoringRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gameCount => $composableBuilder(
      column: $table.gameCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gamesPlayed => $composableBuilder(
      column: $table.gamesPlayed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playTo => $composableBuilder(
      column: $table.playTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get winBy => $composableBuilder(
      column: $table.winBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamAPlayers => $composableBuilder(
      column: $table.teamAPlayers,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamBPlayers => $composableBuilder(
      column: $table.teamBPlayers,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get finalScores => $composableBuilder(
      column: $table.finalScores, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get winner => $composableBuilder(
      column: $table.winner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$CompletedMatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedMatchesTable> {
  $$CompletedMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get scoringRule => $composableBuilder(
      column: $table.scoringRule, builder: (column) => column);

  GeneratedColumn<int> get gameCount =>
      $composableBuilder(column: $table.gameCount, builder: (column) => column);

  GeneratedColumn<int> get gamesPlayed => $composableBuilder(
      column: $table.gamesPlayed, builder: (column) => column);

  GeneratedColumn<int> get playTo =>
      $composableBuilder(column: $table.playTo, builder: (column) => column);

  GeneratedColumn<int> get winBy =>
      $composableBuilder(column: $table.winBy, builder: (column) => column);

  GeneratedColumn<String> get teamAPlayers => $composableBuilder(
      column: $table.teamAPlayers, builder: (column) => column);

  GeneratedColumn<String> get teamBPlayers => $composableBuilder(
      column: $table.teamBPlayers, builder: (column) => column);

  GeneratedColumn<String> get finalScores => $composableBuilder(
      column: $table.finalScores, builder: (column) => column);

  GeneratedColumn<String> get winner =>
      $composableBuilder(column: $table.winner, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  Expression<T> matchEventLogRefs<T extends Object>(
      Expression<T> Function($$MatchEventLogTableAnnotationComposer a) f) {
    final $$MatchEventLogTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.matchEventLog,
        getReferencedColumn: (t) => t.completedMatchId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MatchEventLogTableAnnotationComposer(
              $db: $db,
              $table: $db.matchEventLog,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CompletedMatchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CompletedMatchesTable,
    CompletedMatche,
    $$CompletedMatchesTableFilterComposer,
    $$CompletedMatchesTableOrderingComposer,
    $$CompletedMatchesTableAnnotationComposer,
    $$CompletedMatchesTableCreateCompanionBuilder,
    $$CompletedMatchesTableUpdateCompanionBuilder,
    (CompletedMatche, $$CompletedMatchesTableReferences),
    CompletedMatche,
    PrefetchHooks Function({bool matchEventLogRefs})> {
  $$CompletedMatchesTableTableManager(
      _$AppDatabase db, $CompletedMatchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedMatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedMatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> scoringRule = const Value.absent(),
            Value<int> gameCount = const Value.absent(),
            Value<int> gamesPlayed = const Value.absent(),
            Value<int> playTo = const Value.absent(),
            Value<int> winBy = const Value.absent(),
            Value<String> teamAPlayers = const Value.absent(),
            Value<String> teamBPlayers = const Value.absent(),
            Value<String> finalScores = const Value.absent(),
            Value<String> winner = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
          }) =>
              CompletedMatchesCompanion(
            id: id,
            type: type,
            scoringRule: scoringRule,
            gameCount: gameCount,
            gamesPlayed: gamesPlayed,
            playTo: playTo,
            winBy: winBy,
            teamAPlayers: teamAPlayers,
            teamBPlayers: teamBPlayers,
            finalScores: finalScores,
            winner: winner,
            durationSeconds: durationSeconds,
            startedAt: startedAt,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required String scoringRule,
            required int gameCount,
            required int gamesPlayed,
            required int playTo,
            required int winBy,
            required String teamAPlayers,
            required String teamBPlayers,
            required String finalScores,
            required String winner,
            required int durationSeconds,
            required DateTime startedAt,
            required DateTime completedAt,
          }) =>
              CompletedMatchesCompanion.insert(
            id: id,
            type: type,
            scoringRule: scoringRule,
            gameCount: gameCount,
            gamesPlayed: gamesPlayed,
            playTo: playTo,
            winBy: winBy,
            teamAPlayers: teamAPlayers,
            teamBPlayers: teamBPlayers,
            finalScores: finalScores,
            winner: winner,
            durationSeconds: durationSeconds,
            startedAt: startedAt,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CompletedMatchesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({matchEventLogRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (matchEventLogRefs) db.matchEventLog
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (matchEventLogRefs)
                    await $_getPrefetchedData<CompletedMatche,
                            $CompletedMatchesTable, MatchEventLogData>(
                        currentTable: table,
                        referencedTable: $$CompletedMatchesTableReferences
                            ._matchEventLogRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CompletedMatchesTableReferences(db, table, p0)
                                .matchEventLogRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.completedMatchId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CompletedMatchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CompletedMatchesTable,
    CompletedMatche,
    $$CompletedMatchesTableFilterComposer,
    $$CompletedMatchesTableOrderingComposer,
    $$CompletedMatchesTableAnnotationComposer,
    $$CompletedMatchesTableCreateCompanionBuilder,
    $$CompletedMatchesTableUpdateCompanionBuilder,
    (CompletedMatche, $$CompletedMatchesTableReferences),
    CompletedMatche,
    PrefetchHooks Function({bool matchEventLogRefs})>;
typedef $$MatchEventLogTableCreateCompanionBuilder = MatchEventLogCompanion
    Function({
  Value<int> id,
  required int completedMatchId,
  required int gameNumber,
  required String eventType,
  Value<String?> scorerTeam,
  Value<String?> serverName,
  required int teamAScore,
  required int teamBScore,
  Value<int?> serverNumber,
  required DateTime timestamp,
});
typedef $$MatchEventLogTableUpdateCompanionBuilder = MatchEventLogCompanion
    Function({
  Value<int> id,
  Value<int> completedMatchId,
  Value<int> gameNumber,
  Value<String> eventType,
  Value<String?> scorerTeam,
  Value<String?> serverName,
  Value<int> teamAScore,
  Value<int> teamBScore,
  Value<int?> serverNumber,
  Value<DateTime> timestamp,
});

final class $$MatchEventLogTableReferences extends BaseReferences<_$AppDatabase,
    $MatchEventLogTable, MatchEventLogData> {
  $$MatchEventLogTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CompletedMatchesTable _completedMatchIdTable(_$AppDatabase db) =>
      db.completedMatches.createAlias($_aliasNameGenerator(
          db.matchEventLog.completedMatchId, db.completedMatches.id));

  $$CompletedMatchesTableProcessedTableManager get completedMatchId {
    final $_column = $_itemColumn<int>('completed_match_id')!;

    final manager =
        $$CompletedMatchesTableTableManager($_db, $_db.completedMatches)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedMatchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MatchEventLogTableFilterComposer
    extends Composer<_$AppDatabase, $MatchEventLogTable> {
  $$MatchEventLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gameNumber => $composableBuilder(
      column: $table.gameNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scorerTeam => $composableBuilder(
      column: $table.scorerTeam, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverName => $composableBuilder(
      column: $table.serverName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get teamAScore => $composableBuilder(
      column: $table.teamAScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get teamBScore => $composableBuilder(
      column: $table.teamBScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  $$CompletedMatchesTableFilterComposer get completedMatchId {
    final $$CompletedMatchesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.completedMatchId,
        referencedTable: $db.completedMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CompletedMatchesTableFilterComposer(
              $db: $db,
              $table: $db.completedMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MatchEventLogTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchEventLogTable> {
  $$MatchEventLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gameNumber => $composableBuilder(
      column: $table.gameNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scorerTeam => $composableBuilder(
      column: $table.scorerTeam, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverName => $composableBuilder(
      column: $table.serverName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get teamAScore => $composableBuilder(
      column: $table.teamAScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get teamBScore => $composableBuilder(
      column: $table.teamBScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  $$CompletedMatchesTableOrderingComposer get completedMatchId {
    final $$CompletedMatchesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.completedMatchId,
        referencedTable: $db.completedMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CompletedMatchesTableOrderingComposer(
              $db: $db,
              $table: $db.completedMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MatchEventLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchEventLogTable> {
  $$MatchEventLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get gameNumber => $composableBuilder(
      column: $table.gameNumber, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get scorerTeam => $composableBuilder(
      column: $table.scorerTeam, builder: (column) => column);

  GeneratedColumn<String> get serverName => $composableBuilder(
      column: $table.serverName, builder: (column) => column);

  GeneratedColumn<int> get teamAScore => $composableBuilder(
      column: $table.teamAScore, builder: (column) => column);

  GeneratedColumn<int> get teamBScore => $composableBuilder(
      column: $table.teamBScore, builder: (column) => column);

  GeneratedColumn<int> get serverNumber => $composableBuilder(
      column: $table.serverNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$CompletedMatchesTableAnnotationComposer get completedMatchId {
    final $$CompletedMatchesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.completedMatchId,
        referencedTable: $db.completedMatches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CompletedMatchesTableAnnotationComposer(
              $db: $db,
              $table: $db.completedMatches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MatchEventLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MatchEventLogTable,
    MatchEventLogData,
    $$MatchEventLogTableFilterComposer,
    $$MatchEventLogTableOrderingComposer,
    $$MatchEventLogTableAnnotationComposer,
    $$MatchEventLogTableCreateCompanionBuilder,
    $$MatchEventLogTableUpdateCompanionBuilder,
    (MatchEventLogData, $$MatchEventLogTableReferences),
    MatchEventLogData,
    PrefetchHooks Function({bool completedMatchId})> {
  $$MatchEventLogTableTableManager(_$AppDatabase db, $MatchEventLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchEventLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchEventLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchEventLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> completedMatchId = const Value.absent(),
            Value<int> gameNumber = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String?> scorerTeam = const Value.absent(),
            Value<String?> serverName = const Value.absent(),
            Value<int> teamAScore = const Value.absent(),
            Value<int> teamBScore = const Value.absent(),
            Value<int?> serverNumber = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              MatchEventLogCompanion(
            id: id,
            completedMatchId: completedMatchId,
            gameNumber: gameNumber,
            eventType: eventType,
            scorerTeam: scorerTeam,
            serverName: serverName,
            teamAScore: teamAScore,
            teamBScore: teamBScore,
            serverNumber: serverNumber,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int completedMatchId,
            required int gameNumber,
            required String eventType,
            Value<String?> scorerTeam = const Value.absent(),
            Value<String?> serverName = const Value.absent(),
            required int teamAScore,
            required int teamBScore,
            Value<int?> serverNumber = const Value.absent(),
            required DateTime timestamp,
          }) =>
              MatchEventLogCompanion.insert(
            id: id,
            completedMatchId: completedMatchId,
            gameNumber: gameNumber,
            eventType: eventType,
            scorerTeam: scorerTeam,
            serverName: serverName,
            teamAScore: teamAScore,
            teamBScore: teamBScore,
            serverNumber: serverNumber,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MatchEventLogTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({completedMatchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (completedMatchId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.completedMatchId,
                    referencedTable: $$MatchEventLogTableReferences
                        ._completedMatchIdTable(db),
                    referencedColumn: $$MatchEventLogTableReferences
                        ._completedMatchIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MatchEventLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MatchEventLogTable,
    MatchEventLogData,
    $$MatchEventLogTableFilterComposer,
    $$MatchEventLogTableOrderingComposer,
    $$MatchEventLogTableAnnotationComposer,
    $$MatchEventLogTableCreateCompanionBuilder,
    $$MatchEventLogTableUpdateCompanionBuilder,
    (MatchEventLogData, $$MatchEventLogTableReferences),
    MatchEventLogData,
    PrefetchHooks Function({bool completedMatchId})>;
typedef $$RecentPlayersTableCreateCompanionBuilder = RecentPlayersCompanion
    Function({
  required String name,
  required DateTime lastUsed,
  Value<int> usageCount,
  Value<int> rowid,
});
typedef $$RecentPlayersTableUpdateCompanionBuilder = RecentPlayersCompanion
    Function({
  Value<String> name,
  Value<DateTime> lastUsed,
  Value<int> usageCount,
  Value<int> rowid,
});

class $$RecentPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $RecentPlayersTable> {
  $$RecentPlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsed => $composableBuilder(
      column: $table.lastUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnFilters(column));
}

class $$RecentPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentPlayersTable> {
  $$RecentPlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsed => $composableBuilder(
      column: $table.lastUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnOrderings(column));
}

class $$RecentPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentPlayersTable> {
  $$RecentPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsed =>
      $composableBuilder(column: $table.lastUsed, builder: (column) => column);

  GeneratedColumn<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => column);
}

class $$RecentPlayersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecentPlayersTable,
    RecentPlayer,
    $$RecentPlayersTableFilterComposer,
    $$RecentPlayersTableOrderingComposer,
    $$RecentPlayersTableAnnotationComposer,
    $$RecentPlayersTableCreateCompanionBuilder,
    $$RecentPlayersTableUpdateCompanionBuilder,
    (
      RecentPlayer,
      BaseReferences<_$AppDatabase, $RecentPlayersTable, RecentPlayer>
    ),
    RecentPlayer,
    PrefetchHooks Function()> {
  $$RecentPlayersTableTableManager(_$AppDatabase db, $RecentPlayersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentPlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentPlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentPlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<DateTime> lastUsed = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecentPlayersCompanion(
            name: name,
            lastUsed: lastUsed,
            usageCount: usageCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String name,
            required DateTime lastUsed,
            Value<int> usageCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecentPlayersCompanion.insert(
            name: name,
            lastUsed: lastUsed,
            usageCount: usageCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecentPlayersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecentPlayersTable,
    RecentPlayer,
    $$RecentPlayersTableFilterComposer,
    $$RecentPlayersTableOrderingComposer,
    $$RecentPlayersTableAnnotationComposer,
    $$RecentPlayersTableCreateCompanionBuilder,
    $$RecentPlayersTableUpdateCompanionBuilder,
    (
      RecentPlayer,
      BaseReferences<_$AppDatabase, $RecentPlayersTable, RecentPlayer>
    ),
    RecentPlayer,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ActiveMatchesTableTableManager get activeMatches =>
      $$ActiveMatchesTableTableManager(_db, _db.activeMatches);
  $$ActiveMatchPlayersTableTableManager get activeMatchPlayers =>
      $$ActiveMatchPlayersTableTableManager(_db, _db.activeMatchPlayers);
  $$ScoreEventsTableTableManager get scoreEvents =>
      $$ScoreEventsTableTableManager(_db, _db.scoreEvents);
  $$CompletedMatchesTableTableManager get completedMatches =>
      $$CompletedMatchesTableTableManager(_db, _db.completedMatches);
  $$MatchEventLogTableTableManager get matchEventLog =>
      $$MatchEventLogTableTableManager(_db, _db.matchEventLog);
  $$RecentPlayersTableTableManager get recentPlayers =>
      $$RecentPlayersTableTableManager(_db, _db.recentPlayers);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
