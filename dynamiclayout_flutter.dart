// DynamicLayout Flutter renderer — renders PFDL JSON in Flutter apps.
// Single-file widget. Zero dependencies beyond Flutter SDK.
// Works on Flutter 3.16+ (iOS, Android, Web, Desktop).
//
// Example:
//   DynamicLayout(
//     spec: {'title': 'My Page', 'layout': [{'type': 'LABEL', 'key': 'l', 'label': 'Hello'}]},
//     data: {'name': 'John'},
//     onUpdate: (data) => print(data),
//   )

import 'package:flutter/material.dart';

typedef UpdateCallback = void Function(Map<String, dynamic> data);

class DynamicLayout extends StatefulWidget {
  final Map<String, dynamic>? spec;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>>? errors;
  final UpdateCallback? onUpdate;
  final void Function(String id, Map<String, dynamic>? action)? onAction;

  const DynamicLayout({super.key, this.spec, this.data = const {}, this.errors, this.onUpdate, this.onAction});

  @override
  State<DynamicLayout> createState() => _DynamicLayoutState();
}

class _DynamicLayoutState extends State<DynamicLayout> {
  late Map<String, dynamic> _data;

  @override void initState() { super.initState(); _data = Map.from(widget.data); }

  void _setData(Map<String, dynamic> update) {
    setState(() { _data.addAll(update); });
    widget.onUpdate?.call(Map.from(_data));
  }

  @override Widget build(BuildContext context) {
    final spec = widget.spec;
    if (spec == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (spec['title'] != null)
          Text(spec['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (spec['title'] != null) const SizedBox(height: 16),
        ..._buildList(spec['layout'] as List? ?? []),
        if ((spec['actions'] as List?)?.isNotEmpty ?? false) ...[
          const Divider(),
          Wrap(spacing: 8, children: _buildActions(spec['actions'] as List)),
        ],
      ]),
    );
  }

  List<Widget> _buildList(List list) => list.map((el) => _buildEl(el as Map<String, dynamic>)).toList();

  List<Widget> _buildActions(List list) => list.map((el) => _buildEl(el as Map<String, dynamic>)).toList();

  Widget _buildEl(Map<String, dynamic> el) {
    switch (el['type']) {
      case 'ROW': return Row(children: _buildList(el['content'] as List? ?? []));
      case 'COL': return Expanded(child: Column(children: _buildList(el['content'] as List? ?? [])));
      case 'FIELDSET': return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (el['title'] != null) Text(el['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ..._buildList(el['content'] as List? ?? []),
      ])));
      case 'GROUP': return Column(children: _buildList(el['content'] as List? ?? []));
      case 'LABEL': return Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(el['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)));
      case 'ALERT':
        final colors = {'info': Colors.blue.shade50, 'warning': Colors.amber.shade50, 'danger': Colors.red.shade50, 'success': Colors.green.shade50};
        return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: colors[el['color']] ?? Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text(el['message'] ?? ''));
      case 'BADGE':
        final colors = {'primary': Colors.blue, 'secondary': Colors.grey, 'success': Colors.green, 'danger': Colors.red};
        return Chip(label: Text(el['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: colors[el['color']] ?? Colors.grey);
      case 'SPACER': return SizedBox(height: (el['width'] as num?)?.toDouble() ?? 20);
      case 'PROGRESS': return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (el['label'] != null) Text(el['label']),
        LinearProgressIndicator(value: ((el['progress'] as num?)?.toDouble() ?? 0) / 100),
      ]);
      case 'INPUT': return _buildInput(el);
      case 'CHECKBOX': return CheckboxListTile(title: Text(el['label'] ?? ''), value: _data[el['id']] == true, onChanged: (v) => _setData({el['id']: v}));
      case 'TEXTAREA': return TextFormField(initialValue: _data[el['id']]?.toString() ?? '', decoration: InputDecoration(labelText: el['label']), maxLines: el['rows'] ?? 3, onChanged: (v) => _setData({el['id']: v}));
      case 'SELECT': return DropdownButtonFormField<String>(
        value: _data[el['id']]?.toString(),
        decoration: InputDecoration(labelText: el['label']),
        items: (el['values'] as List? ?? []).map<DropdownMenuItem<String>>((v) => DropdownMenuItem(value: v['id'].toString(), child: Text(v['displayName'] ?? ''))).toList(),
        onChanged: (v) => _setData({el['id']: v}),
      );
      case 'RATING': return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (el['label'] != null) Text(el['label'] ?? ''),
        Row(children: List.generate(5, (i) => IconButton(
          icon: Icon(i < (_data[el['id']] as num?)?.toInt() ?? 0 ? Icons.star : Icons.star_border, color: Colors.amber),
          onPressed: () => _setData({el['id']: i + 1}),
        ))),
      ]);
      case 'READONLY_FIELD': return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (el['label'] != null) Text(el['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(padding: const EdgeInsets.all(8), width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)), child: Text(_data[el['id']]?.toString() ?? '—')),
      ]);
      case 'BUTTON':
        final colors = {'primary': Colors.blue, 'secondary': Colors.grey, 'success': Colors.green, 'danger': Colors.red};
        return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: colors[el['color']] ?? Colors.blue),
          onPressed: () => widget.onAction?.call(el['id'] ?? '', el['responseAction'] as Map<String, dynamic>?),
          child: Text(el['title'] ?? el['id'] ?? '', style: const TextStyle(color: Colors.white)),
        );
      default: return Text('Unknown: ${el['type']}', style: const TextStyle(color: Colors.red));
    }
  }

  Widget _buildInput(Map<String, dynamic> el) {
    final dt = el['dataType'] ?? 'STRING';
    final err = widget.errors?.firstWhere((e) => e['fieldId'] == el['id'], orElse: () => {});
    TextInputType keyboard = TextInputType.text;
    bool obscure = false;
    if (dt == 'PASSWORD') obscure = true;
    if (dt == 'INTEGER' || dt == 'LONG' || dt == 'BIG_DECIMAL') keyboard = TextInputType.number;

    final ctrl = TextEditingController(text: _data[el['id']]?.toString() ?? '');

    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      maxLength: el['maxLength'] as int?,
      decoration: InputDecoration(
        labelText: el['label'],
        errorText: err != null && err['message'] != null ? err['message'].toString() : null,
      ),
      onChanged: (v) => _setData({el['id']: dt == 'INTEGER' || dt == 'LONG' ? int.tryParse(v) : v}),
    );
  }
}
