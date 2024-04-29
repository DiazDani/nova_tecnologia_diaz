import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProvaWidget extends StatefulWidget {
  @override
  _ProvaWidgetState createState() => _ProvaWidgetState();
}

class _ProvaWidgetState extends State<ProvaWidget> {
  // Declaramos una lista para almacenar los datos de los Pokémon
  List<dynamic> pokemonList = [];
  List<dynamic> displayedPokemonList = [];

  // Controlador para el campo de texto de búsqueda
  final TextEditingController _searchController = TextEditingController();

  // Método para obtener los datos de los Pokémon desde tu servidor Node.js
  Future<void> fetchPokemons() async {
    final response = await http.get(Uri.parse('http://192.168.16.143:3000/pokemons'));
    if (response.statusCode == 200) {
      setState(() {
        pokemonList = json.decode(response.body)['results'];
        // Inicializar displayedPokemonList con la lista completa de Pokémon
        displayedPokemonList = List.from(pokemonList);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPokemons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon Team Builder'),
      ),
      body: Column(
        children: [
          // Campo de texto para la búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar Pokémon',
              hintText: 'Ingrese el nombre del Pokémon',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              // Filtrar la lista de Pokémon según la entrada del usuario
              setState(() {
                displayedPokemonList = pokemonList.where((pokemon) =>
                    pokemon['name'].toLowerCase().contains(value.toLowerCase())).toList();
              });
            },
          ),
          Expanded(
            child: displayedPokemonList.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: displayedPokemonList.length,
                    itemBuilder: (context, index) {
                      final pokemon = displayedPokemonList[index];
                      return ListTile(
                        title: Text(
                          pokemon['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PokemonDetailsScreen(pokemonUrl: pokemon['url']),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar los detalles de un Pokémon
class PokemonDetailsScreen extends StatelessWidget {
  final String pokemonUrl;

  PokemonDetailsScreen({required this.pokemonUrl});

  Future<Map<String, dynamic>> fetchPokemonDetails() async {
    final response = await http.get(Uri.parse(pokemonUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokemon Details'),
      ),
      body: FutureBuilder(
        future: fetchPokemonDetails(),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final pokemon = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.network(
                    pokemon['sprites']['front_default'],
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Name: ${pokemon['name']}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Height: ${pokemon['height']}'),
                  SizedBox(height: 10),
                  Text('Weight: ${pokemon['weight']}'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}