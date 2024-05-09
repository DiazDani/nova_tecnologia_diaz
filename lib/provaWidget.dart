import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Widget principal que mostra la llista de Pokémon i permet buscar-los
class ProvaWidget extends StatefulWidget {
  @override
  _ProvaWidgetState createState() => _ProvaWidgetState();
}

class _ProvaWidgetState extends State<ProvaWidget> {
  List<dynamic> pokemonList = [];
  List<dynamic> displayedPokemonList = [];
  final TextEditingController _searchController = TextEditingController();

  // Funció per obtenir la llista de Pokémon desde l'API
  Future<void> fetchPokemons() async {

        //CANVIAR LA IP O NO FUNCIONARÀ

    final response = await http.get(Uri.parse('http://192.168.1.174:3080/pokemons'));
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
          // Camp de busqueda per filtrar la llista de Pokémon
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Pokémon',
              hintText: 'Enter a Pokémon Name',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  displayedPokemonList = pokemonList.where((pokemon) =>
                      pokemon['name'].toLowerCase().contains(value.toLowerCase())).toList();
                } else {
                  displayedPokemonList = [];
                }
              });
            },
          ),
          SizedBox(height: 20),
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
                        builder: (context) => PokemonDetailsScreen(
                          pokemonUrl: pokemon['url'],
                          displayedPokemonList: displayedPokemonList,
                        ),
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

// Pantalla de detalls d'un Pokémon, amb opcions per adjustar els valors EVs
class PokemonDetailsScreen extends StatefulWidget {
  final String pokemonUrl;
  final List<dynamic> displayedPokemonList;

  PokemonDetailsScreen({required this.pokemonUrl, required this.displayedPokemonList});

  @override
  _PokemonDetailsScreenState createState() => _PokemonDetailsScreenState();
}

class _PokemonDetailsScreenState extends State<PokemonDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  late Future<Map<String, dynamic>> _pokemonDetailsFuture;
  Future<List<dynamic>>? _firstGenMovesFuture;

  Map<String, dynamic> _pokemonDetails = {};

  List<String> selectedAttacks = ['', '', '', ''];

  List<double> _initialSliderValues = List.filled(5, 252);

  @override
  void initState() {
    super.initState();
    _pokemonDetailsFuture = fetchPokemonDetails();
  }

  // Funció per obtenir els detalls d'un Pokémon desde la API
  Future<Map<String, dynamic>> fetchPokemonDetails() async {
    final response = await http.get(Uri.parse(widget.pokemonUrl));
    if (response.statusCode == 200) {
      _pokemonDetails = json.decode(response.body);
      return _pokemonDetails;
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Funció per obtenir els movimients de primera generació d'un Pokémon desde l'API
  Future<List<dynamic>> fetchFirstGenMoves(String pokemonName) async {

    //CANVIAR LA IP O NO FUNCIONARÀ
    final response = await http.get(Uri.parse('http://192.168.1.174:3080/pokemons/$pokemonName'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['firstGenMoves'] ?? [];
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Función per modificar la cadena de text dels atacs 
  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split('-').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  // Funció per generar el pokepaste amb els valors EVs i atacs seleccionats
  String generatePokepaste(List<double> sliderValues) {
    String pokemonName = _nameController.text.trim();
    String species = capitalize(_pokemonDetails['species']['name']);
    String abilities = 'Ability: No Ability';

    List<String> evs = [
      'EVs: ${sliderValues[0].toInt()} HP',
      '${sliderValues[1].toInt()} Atk',
      '${sliderValues[2].toInt()} Def',
      '${sliderValues[3].toInt()} SpA',
      '${sliderValues[4].toInt()} Spe'
    ];

    List<String> moves = [];
    for (var move in selectedAttacks) {
      if (move.isNotEmpty) {
        moves.add('- $move');
      }
    }

    if (pokemonName.isNotEmpty) {
      pokemonName += ' ($species)';
    } else {
      pokemonName = species;
    }

    String pokepaste = '$pokemonName\n$abilities\n${evs.join(' / ')}\n${moves.join('\n')}';

    return pokepaste;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokemon Details'),
        actions: [
          // Botó per mostrar el pokepaste generat
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Pokepaste'),
                    content: Container(
                      width: double.maxFinite,
                      child: TextField(
                        maxLines: null,
                        readOnly: true,
                        controller: TextEditingController(text: generatePokepaste(_initialSliderValues)),
                        decoration: InputDecoration(border: OutlineInputBorder()),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
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
                        labelText: 'Nickname',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
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
                              SizedBox(height: 10),
                              for (var i = 0; i < 4; i++)
                                DropdownButtonFormField(
                                  decoration: InputDecoration(labelText: 'Select an Attack'),
                                  items: moves.map<DropdownMenuItem<String>>((move) {
                                    return DropdownMenuItem<String>(
                                      value: capitalize(move.toString()),
                                      child: Text(capitalize(move.toString())),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedAttacks[i] = newValue ?? '';
                                    });
                                  },
                                ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SliderDialog(initialValues: _initialSliderValues, onChanged: (sliderValues) {
                              setState(() {
                                _initialSliderValues = sliderValues;
                              });
                            });
                          },
                        );
                      },
                      child: Text('Adjust EVs'),
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

// Widget que mostra el dialeg amb sliders per adjustar els EVs
class SliderDialog extends StatefulWidget {
  final List<double> initialValues;
  final void Function(List<double>)? onChanged;

  SliderDialog({required this.initialValues, this.onChanged});

  @override
  _SliderDialogState createState() => _SliderDialogState();
}

class _SliderDialogState extends State<SliderDialog> {
  late List<double> _sliderValues;

  @override
  void initState() {
    super.initState();
    _sliderValues = List.from(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust EVs'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Column(
            children: [
              Text(
                _getFieldTitle(index),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _sliderValues[index],
                min: 0,
                max: 252,
                divisions: 252,
                onChanged: (value) {
                  setState(() {
                    _sliderValues[index] = value;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(_sliderValues);
                  }
                },
              ),
              Text('Selected value: ${_sliderValues[index].toInt()}'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }

  // Funció per obtenir el titol corresponent a cada Slider
  String _getFieldTitle(int index) {
    switch (index) {
      case 0:
        return 'HP';
      case 1:
        return 'Attack';
      case 2:
        return 'Defense';
      case 3:
        return 'Special';
      case 4:
        return 'Speed';
      default:
        return '';
    }
  }
}

// Widget que mostra el dialeg amb el contingut del Pokepaste
class PokepasteDialog extends StatelessWidget {
  final List<dynamic> pokemonList;

  PokepasteDialog({required this.pokemonList});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pokepaste'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: pokemonList.length,
          itemBuilder: (context, index) {
            final pokemon = pokemonList[index];
            return ListTile(
              title: Text(
                pokemon['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Species: ${pokemon['species']['name']}'),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProvaWidget(),
  ));
}
