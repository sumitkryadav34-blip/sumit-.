import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() => runApp(NexStreamApp());

class NexStreamApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  final List<String> _titles = ["MOVIES", "ANIME", "TV SHOWS", "SERIES"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              decoration: InputDecoration(hintText: "Search...", border: InputBorder.none),
              onSubmitted: (v) => setState(() {}),
            )
          : Text(_titles[_selectedIndex], style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () => setState(() { _isSearching = !_isSearching; if(!_isSearching) _searchController.clear(); }))
        ],
      ),
      body: ContentGrid(categoryIndex: _selectedIndex, searchQuery: _searchController.text),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() { _selectedIndex = index; _isSearching = false; }),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: "Movies"),
          BottomNavigationBarItem(icon: Icon(Icons.animation), label: "Anime"),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: "TV"),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Series"),
        ],
      ),
    );
  }
}

class ContentGrid extends StatefulWidget {
  final int categoryIndex;
  final String searchQuery;
  ContentGrid({required this.categoryIndex, required this.searchQuery});
  @override
  _ContentGridState createState() => _ContentGridState();
}

class _ContentGridState extends State<ContentGrid> {
  final String apiKey = "2bc6e3d99bcfccaaf493af0fe3916b47";
  List dataList = [];
  bool isLoading = true;

  @override
  void initState() { super.initState(); fetchData(); }

  @override
  void didUpdateWidget(ContentGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryIndex != widget.categoryIndex || oldWidget.searchQuery != widget.searchQuery) fetchData();
  }

  fetchData() async {
    setState(() => isLoading = true);
    String url = widget.searchQuery.isNotEmpty 
      ? "https://api.themoviedb.org/3/search/multi?api_key=$apiKey&query=${widget.searchQuery}"
      : (widget.categoryIndex == 0 ? "https://api.themoviedb.org/3/trending/movie/day?api_key=$apiKey" :
         widget.categoryIndex == 1 ? "https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=16" :
         "https://api.themoviedb.org/3/tv/popular?api_key=$apiKey");

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() { dataList = json.decode(response.body)['results']; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        var item = dataList[index];
        if (item['poster_path'] == null) return Container();
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerPage(id: item['id'].toString(), isTv: widget.categoryIndex >= 2))),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network("https://image.tmdb.org/t/p/w500${item['poster_path']}", fit: BoxFit.cover)),
        );
      },
    );
  }
}

class PlayerPage extends StatelessWidget {
  final String id;
  final bool isTv;
  PlayerPage({required this.id, required this.isTv});
  @override
  Widget build(BuildContext context) {
    String url = isTv ? "https://vidsrc.to/embed/tv/$id" : "https://vidsrc.to/embed/movie/$id";
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black),
      body: InAppWebView(initialUrlRequest: URLRequest(url: WebUri(url))),
    );
  }
}
