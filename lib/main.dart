import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(PokemonApp());
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon & Dogs API',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeTabs(),
    );
  }
}

class HomeTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 🔥 Pokémons y Perros
      child: Scaffold(
        appBar: AppBar(
          title: Text("Pokémon & Perros"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.catching_pokemon), text: "Pokémon"),
              Tab(icon: Icon(Icons.pets), text: "Perros"),
              Tab(icon: Icon(Icons.emoji_emotions), text: "Emojis"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PokemonList(),
            DogsList(),
            EmojiTab(),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////
//                   --- POKEMON LISTA ---
//////////////////////////////////////////////////////////////////

class PokemonList extends StatefulWidget {
  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<Map<String, dynamic>> _pokemonList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon() async {
    setState(() => _isLoading = true);

    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        final pokemonDetails = await Future.wait(results.map((pokemon) async {
          final res = await http.get(Uri.parse(pokemon['url']));

          if (res.statusCode == 200) {
            final d = json.decode(res.body);

            return {
              'name': pokemon['name'],
              'image': d['sprites']['front_default'],
              'details': d
            };
          }
          return null;
        }));

        setState(() {
          _pokemonList =
              pokemonDetails.where((p) => p != null).cast<Map<String, dynamic>>().toList();

          _filteredList = List.from(_pokemonList);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void filterSearch(String query) {
    final list = _pokemonList.where((p) {
      final name = p['name'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() => _filteredList = list);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Búsqueda Pokémon
        Padding(
          padding: EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              labelText: "Buscar Pokémon",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: filterSearch,
          ),
        ),

        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    final pokemon = _filteredList[index];

                    return ListTile(
                      leading: pokemon['image'] != null
                          ? Image.network(pokemon['image'])
                          : Icon(Icons.image_not_supported),
                      title: Text(pokemon['name'].toUpperCase()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PokemonDetail(pokemon: pokemon),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class PokemonDetail extends StatelessWidget {
  final Map<String, dynamic> pokemon;

  PokemonDetail({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final details = pokemon['details'];

    return Scaffold(
      appBar: AppBar(title: Text(pokemon['name'].toUpperCase())),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Image.network(pokemon['image'], height: 150),
            SizedBox(height: 15),
            Text(
              pokemon['name'].toUpperCase(),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Divider(),

            Text("ID: ${details['id']}"),
            Text("Altura: ${details['height']}"),
            Text("Peso: ${details['weight']}"),
            Divider(),

            if (details['abilities'] != null) ...[
              Text("Habilidades", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...details["abilities"].map<Widget>(
                (a) => Text("• ${a['ability']['name']}"),
              ),
            ],

            Divider(),

            if (details['types'] != null) ...[
              Text("Tipos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...details["types"].map<Widget>(
                (t) => Text("• ${t['type']['name']}"),
              ),
            ],

            Divider(),

            if (details['stats'] != null) ...[
              Text("Estadísticas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...details["stats"].map<Widget>(
                (s) => Text("${s['stat']['name']}: ${s['base_stat']}"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////
//                   --- DOG API TAB ---
//////////////////////////////////////////////////////////////////

class DogsList extends StatefulWidget {
  @override
  _DogsListState createState() => _DogsListState();
}

class _DogsListState extends State<DogsList> {
  List<String> _breeds = [];
  List<String> _filteredBreeds = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    fetchBreeds();
  }

  // Obtener todas las razas
  Future<void> fetchBreeds() async {
    setState(() => _loading = true);

    final url = Uri.parse('https://dog.ceo/api/breeds/list');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List breeds = data['message'];

      setState(() {
        _breeds = List<String>.from(breeds);
        _filteredBreeds = List<String>.from(_breeds);
        _loading = false;
      });
    }
  }

  // Búsqueda de razas
  void filterDogs(String query) {
    final list = _breeds.where((b) => b.toLowerCase().contains(query.toLowerCase())).toList();
    setState(() => _filteredBreeds = list);
  }

  // Obtener imagen por raza
  Future<String> fetchDogImage(String breed) async {
    final url = Uri.parse("https://dog.ceo/api/breed/$breed/images/random");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["message"];
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Búsqueda perros
        Padding(
          padding: EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              labelText: "Buscar raza de perro",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: filterDogs,
          ),
        ),

        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredBreeds.length,
                  itemBuilder: (context, index) {
                    final breed = _filteredBreeds[index];

                    return ListTile(
                      leading: Icon(Icons.pets),
                      title: Text(breed.toUpperCase()),
                      onTap: () async {
                        final imageUrl = await fetchDogImage(breed);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DogDetail(breed: breed, imageUrl: imageUrl),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////////
//                   --- DETALLE DOG ---
//////////////////////////////////////////////////////////////////

class DogDetail extends StatelessWidget {
  final String breed;
  final String imageUrl;

  DogDetail({required this.breed, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(breed.toUpperCase()),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            imageUrl.isNotEmpty
                ? Image.network(imageUrl, height: 250)
                : Icon(Icons.image_not_supported, size: 150),
            SizedBox(height: 20),
            Text(
              breed.toUpperCase(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}




class EmojiTab extends StatefulWidget {
  const EmojiTab({super.key});

  @override
  State<EmojiTab> createState() => _EmojiTabState();
}

class _EmojiTabState extends State<EmojiTab> {
  List emojis = [];
  Map<String, dynamic>? selectedEmoji;
  final searchController = TextEditingController();

  // --------------------------------------------------
  // FUNCIÓN UNIVERSAL PARA CONVERTIR CUALQUIER FORMATO
  // --------------------------------------------------
  String htmlOrUnicodeToEmoji(List codes) {
    List<int> codePoints = [];

    for (var raw in codes) {
      String cleaned = raw.toString().trim();

      // FORMATO HTML DECIMAL: "&#128512;"
      if (cleaned.startsWith("&#") && cleaned.contains(";")) {
        cleaned = cleaned.replaceAll("&#", "").replaceAll(";", "");
        int cp = int.parse(cleaned);
        codePoints.add(cp);
      }
      // FORMATO HTML HEXA: "&#x1F600;"
      else if (cleaned.startsWith("&#x")) {
        cleaned = cleaned.replaceAll("&#x", "").replaceAll(";", "");
        int cp = int.parse(cleaned, radix: 16);
        codePoints.add(cp);
      }
      // FORMATO "U+1F600"
      else if (cleaned.startsWith("U+")) {
        cleaned = cleaned.replaceAll("U+", "");
        int cp = int.parse(cleaned, radix: 16);
        codePoints.add(cp);
      }
    }

    return String.fromCharCodes(codePoints);
  }

  // --------------------------------------------------
  // API CALLS
  // --------------------------------------------------

  Future<void> loadAllEmojis() async {
    final url = Uri.parse("https://emojihub.yurace.pro/api/all");
    final r = await http.get(url);

    if (r.statusCode == 200) {
      setState(() => emojis = json.decode(r.body));
    }
  }

  Future<void> loadRandomEmoji() async {
    final url = Uri.parse("https://emojihub.yurace.pro/api/random");
    final r = await http.get(url);
    if (r.statusCode == 200) {
      setState(() => selectedEmoji = json.decode(r.body));
    }
  }

  Future<void> searchEmoji(String q) async {
    final url = Uri.parse("https://emojihub.yurace.pro/api/search?q=$q");
    final r = await http.get(url);

    if (r.statusCode == 200) {
      setState(() => emojis = json.decode(r.body));
    }
  }

  @override
  void initState() {
    super.initState();
    loadAllEmojis();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LISTA DE EMOJIS
        Expanded(
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                    labelText: "Buscar Emoji",
                    prefixIcon: Icon(Icons.search)),
                onSubmitted: searchEmoji,
              ),
              ElevatedButton(
                onPressed: loadRandomEmoji,
                child: const Text("Emoji Aleatorio"),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: emojis.length,
                  itemBuilder: (ctx, i) {
                    final e = emojis[i];
                    return ListTile(
                      title: Text(e["name"]),
                      subtitle: Text(e["category"]),
                      trailing: Text(
                        htmlOrUnicodeToEmoji(e["htmlCode"]),
                        style: const TextStyle(fontSize: 26),
                      ),
                      onTap: () => setState(() => selectedEmoji = e),
                    );
                  },
                ),
              )
            ],
          ),
        ),

        // DETALLES DEL EMOJI
        Expanded(
          child: selectedEmoji == null
              ? const Center(child: Text("Selecciona un emoji"))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      htmlOrUnicodeToEmoji(selectedEmoji!["htmlCode"]),
                      style: const TextStyle(fontSize: 60),
                    ),
                    Text(
                      selectedEmoji!["name"],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text("Categoría: ${selectedEmoji!["category"]}"),
                    Text("Grupo: ${selectedEmoji!["group"]}"),
                  ],
                ),
        ),
      ],
    );
  }
}
