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
    final response = await http.get(Uri.parse('http://192.168.19.206:3000/pokemons'));
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Row( // Utilizamos Row para alinear la imagen a la izquierda
                      mainAxisAlignment: MainAxisAlignment.start, // Alineamos al inicio
                      children: [
                        Image.network(
                          pokemon['sprites']['front_default'],
                          height: 150, // Reducimos el tamaño de la imagen
                          width: 150, // Reducimos el tamaño de la imagen
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Introduce el nombre del Pokémon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Ataque',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Ataque',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Ataque',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Ataque',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
