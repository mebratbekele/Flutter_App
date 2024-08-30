import 'package:flutter/material.dart';

class JobSearchDelegate extends SearchDelegate {
  final void Function(String query) onQueryChanged;

  JobSearchDelegate({required this.onQueryChanged});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          onQueryChanged(query); // Update search results
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onQueryChanged(query); // Update search results based on query
    return Container(); // Placeholder for search results
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Placeholder for suggestions if needed
  }
}
