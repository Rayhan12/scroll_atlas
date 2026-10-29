// API diff for package:scroll_atlas/compat.dart.
//
// Reads the public API of scrollable_positioned_list and
// linked_scroll_controller from this package's dependencies and checks
// that every public class, member and named parameter exists in
// compat.dart. Each difference must be listed in [knownDifferences].
// Run from benchmark/:
//
//   dart run tool/compat_api_diff.dart
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Known differences from the original packages.
const Map<String, String> knownDifferences = {
  'ScrollablePositionedList.itemPositionsNotifier':
      'Field of the old widget. Pass itemPositionsListener as before.',
  'ScrollablePositionedList.scrollOffsetNotifier':
      'Field of the old widget. Pass scrollOffsetListener as before.',
};

/// One public member: a constructor, method, getter, setter or field.
final class Member {
  Member(this.name, this.named, this.positional);

  final String name;
  final Set<String> named;
  final int positional;
}

/// A class, mixin or typedef with its members and supertypes.
final class TypeInfo {
  TypeInfo(this.name);

  final String name;
  final Map<String, Member> members = {};
  final List<String> supertypes = [];
  String? aliasOf;
}

Map<String, TypeInfo> parseTypes(Iterable<File> files) {
  final types = <String, TypeInfo>{};
  for (final file in files) {
    final unit =
        parseString(
          content: file.readAsStringSync(),
          throwIfDiagnostics: false,
        ).unit;
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        final info =
            types[declaration.name.lexeme] = TypeInfo(declaration.name.lexeme);
        info.supertypes.addAll([
          if (declaration.extendsClause case final clause?)
            clause.superclass.name2.lexeme,
          ...?declaration.withClause?.mixinTypes.map((t) => t.name2.lexeme),
          ...?declaration.implementsClause?.interfaces.map(
            (t) => t.name2.lexeme,
          ),
        ]);
        _addMembers(info, declaration.members);
      } else if (declaration is MixinDeclaration) {
        _addMembers(
          types[declaration.name.lexeme] = TypeInfo(declaration.name.lexeme),
          declaration.members,
        );
      } else if (declaration is GenericTypeAlias) {
        final type = declaration.type;
        if (type is NamedType) {
          types[declaration.name.lexeme] = TypeInfo(declaration.name.lexeme)
            ..aliasOf = type.name2.lexeme;
        }
      }
    }
  }
  return types;
}

void _addMembers(TypeInfo info, Iterable<ClassMember> members) {
  for (final member in members) {
    switch (member) {
      case ConstructorDeclaration():
        final name = member.name?.lexeme ?? 'new';
        info.members['new $name'] = _member('new $name', member.parameters);
      case MethodDeclaration():
        final prefix = member.isSetter ? 'set ' : '';
        final name = '$prefix${member.name.lexeme}';
        info.members[name] = _member(name, member.parameters);
      case FieldDeclaration():
        for (final variable in member.fields.variables) {
          info.members[variable.name.lexeme] = Member(
            variable.name.lexeme,
            const {},
            0,
          );
        }
    }
  }
}

Member _member(String name, FormalParameterList? parameters) {
  final named = <String>{};
  var positional = 0;
  for (final parameter in parameters?.parameters ?? <FormalParameter>[]) {
    if (parameter.isNamed) {
      named.add(parameter.name!.lexeme);
    } else {
      positional++;
    }
  }
  return Member(name, named, positional);
}

bool _isPublic(String name) =>
    !name.split(' ').last.startsWith('_') && name != 'new _';

/// Finds [member] on [type] or anything it extends, mixes in or
/// implements.
Member? lookup(Map<String, TypeInfo> types, String type, String member) {
  final info = types[type];
  if (info == null) return null;
  if (info.aliasOf case final target?) return lookup(types, target, member);
  if (info.members[member] case final found?) return found;
  if (member.startsWith('new ')) {
    final hasConstructors = info.members.keys.any((k) => k.startsWith('new '));
    // A class without constructors has the implicit `new()`.
    return member == 'new new' && !hasConstructors
        ? Member(member, const {}, 0)
        : null;
  }
  for (final supertype in info.supertypes) {
    if (lookup(types, supertype, member) case final found?) return found;
  }
  return null;
}

/// Files a library exports, following `export` directives in its package.
List<File> exportedFiles(File library) {
  final unit =
      parseString(
        content: library.readAsStringSync(),
        throwIfDiagnostics: false,
      ).unit;
  final exports = unit.directives.whereType<ExportDirective>().toList();
  if (exports.isEmpty) return [library];
  return [
    for (final export in exports)
      if (export.uri.stringValue case final uri? when !uri.contains(':'))
        ...exportedFiles(File.fromUri(library.uri.resolve(uri))),
  ];
}

Directory packageLib(String name) {
  final config = File('.dart_tool/package_config.json');
  final json = jsonDecode(config.readAsStringSync()) as Map<String, Object?>;
  final packages = (json['packages']! as List).cast<Map<String, Object?>>();
  final package = packages.firstWhere((p) => p['name'] == name);
  final root = config.uri.resolve('${package['rootUri']}/');
  return Directory.fromUri(root.resolve('${package['packageUri']}'));
}

void main() {
  final atlasLib = packageLib('scroll_atlas');
  final atlasTypes = parseTypes(
    atlasLib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')),
  );
  final compatNames =
      parseTypes(
        exportedFiles(File('${atlasLib.path}compat.dart')),
      ).keys.where(_isPublic).toSet();

  final differences = <String>{};
  var checked = 0;
  for (final package in [
    'scrollable_positioned_list',
    'linked_scroll_controller',
  ]) {
    final lib = packageLib(package);
    final oldTypes = parseTypes(
      exportedFiles(File('${lib.path}$package.dart')),
    );
    for (final type in oldTypes.values.where((t) => _isPublic(t.name))) {
      checked++;
      if (!compatNames.contains(type.name)) {
        differences.add(type.name);
        continue;
      }
      for (final member in type.members.values) {
        if (!_isPublic(member.name)) continue;
        checked++;
        final key = '${type.name}.${member.name}';
        final found = lookup(atlasTypes, type.name, member.name);
        if (found == null) {
          differences.add(key);
          continue;
        }
        for (final name in member.named.difference(found.named)) {
          differences.add('$key($name:)');
        }
        if (found.positional < member.positional) {
          differences.add('$key(positional)');
        }
      }
    }
  }

  final unlisted = differences.difference(knownDifferences.keys.toSet());
  final stale = knownDifferences.keys.toSet().difference(differences);
  stdout.writeln('Checked $checked public names of the old packages.');
  for (final key in differences) {
    stdout.writeln('  known: $key: ${knownDifferences[key] ?? 'UNLISTED'}');
  }
  for (final key in unlisted) {
    stderr.writeln('Missing from compat.dart and not documented: $key');
  }
  for (final key in stale) {
    stderr.writeln('Listed as a difference but now matches: $key');
  }
  if (unlisted.isNotEmpty || stale.isNotEmpty) exitCode = 1;
}
