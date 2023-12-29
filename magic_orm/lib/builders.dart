import 'package:build/build.dart';

import 'src/builder/builders/json_builder.dart';
import 'src/builder/builders/models_exporter_builder.dart';
import 'src/builder/builders/relation_info_builder.dart';
import 'src/builder/builders/schema_builder.dart';
import 'src/builder/builders/analyzing_builder.dart';

export 'src/core/case_style.dart' show CaseStyle, TextTransform;

Builder buildRelationInfos(BuilderOptions options) =>
    RelationInfoBuilder(options);

Builder buildModelsExporter(BuilderOptions options) =>
    ModelsExporterBuilder(options);

Builder analyzeSchema(BuilderOptions options) => AnalyzingBuilder(options);

Builder buildSchema(BuilderOptions options) => SchemaBuilder(options);

Builder buildRunner(BuilderOptions options) => JsonBuilder(options);
