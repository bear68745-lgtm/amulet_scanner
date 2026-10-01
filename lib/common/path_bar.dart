import 'package:flutter/material.dart';

class PathBar extends StatelessWidget {
final List<String> items;

const PathBar({
super.key,
required this.items,
});

@override
Widget build(BuildContext context) {
return SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
for (int i = 0; i < items.length; i++) ...[
Text(
items[i],
style: const TextStyle(
fontSize: 14,
),
),
if (i < items.length - 1)
const Padding(
padding: EdgeInsets.symmetric(horizontal: 6),
child: Icon(
Icons.chevron_right,
size: 18,
),
),
],
],
),
);
}
}
