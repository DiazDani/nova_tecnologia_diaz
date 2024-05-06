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
    final response = await http.get(Uri.parse('http://192.168.19.144:3000/pokemons'));
    if (response.statusCode == 200) {
      setState(() {
        pokemonList = json.decode(response.body)['results'];
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
              setState(() {
                // Filtrar la lista de Pokémon solo si el campo de texto no está vacío
                if (value.isNotEmpty) {
                  displayedPokemonList = pokemonList.where((pokemon) =>
                      pokemon['name'].toLowerCase().contains(value.toLowerCase())).toList();
                } else {
                  // Si el campo de texto está vacío, no mostrar ninguna opción
                  displayedPokemonList = [];
                }
              });
            },
          ),
          // Mostrar la lista solo si hay opciones disponibles
          if (displayedPokemonList.isNotEmpty)
            Expanded(
              child: ListView.builder(
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
// Widget para mostrar los detalles de un Pokémon
class PokemonDetailsScreen extends StatefulWidget {
  final String pokemonUrl;

  PokemonDetailsScreen({required this.pokemonUrl});

  @override
  _PokemonDetailsScreenState createState() => _PokemonDetailsScreenState();
}

class _PokemonDetailsScreenState extends State<PokemonDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();

  late Future<Map<String, dynamic>> _pokemonDetailsFuture;
  Future<List<dynamic>>? _firstGenMovesFuture;

  @override
  void initState() {
    super.initState();
    _pokemonDetailsFuture = fetchPokemonDetails();
  }

  Future<Map<String, dynamic>> fetchPokemonDetails() async {
    final response = await http.get(Uri.parse(widget.pokemonUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<List<dynamic>> fetchFirstGenMoves(String pokemonName) async {
    final response = await http.get(Uri.parse('http://192.168.19.144:3000/pokemons/$pokemonName'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['firstGenMoves'] ?? [];
    } else {
      throw Exception('Failed to load data');
    }
  }

  List<dynamic> filterMoves(List<dynamic> moves, String searchText) {
    return moves.where((move) => move.toString().toLowerCase().contains(searchText.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokemon Details'),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: _pokemonDetailsFuture,
          builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final pokemon = snapshot.data!;
              if (_firstGenMovesFuture == null) {
                _firstGenMovesFuture = fetchFirstGenMoves(pokemon['name']);
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.network(
                          pokemon['sprites']['front_default'],
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Introduce el nombre del Pokémon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    FutureBuilder(
                      future: _firstGenMovesFuture,
                      builder: (context, AsyncSnapshot<List<dynamic>> movesSnapshot) {
                        if (movesSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (movesSnapshot.hasError) {
                          return Center(child: Text('Error: ${movesSnapshot.error}'));
                        } else {
                          final moves = movesSnapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Movimientos de la primera generación:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              for (var i = 0; i < 4; i++)
                                DropdownButtonFormField(
                                  decoration: InputDecoration(labelText: 'Selecciona un ataque para Ataque ${i + 1}'),
                                  items: moves.map<DropdownMenuItem<String>>((move) {
                                    return DropdownMenuItem<String>(
                                      value: move.toString(),
                                      child: Text(move.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      // Aquí puedes realizar cualquier acción que necesites cuando se cambie un ataque
                                    });
                                  },
                                ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}



