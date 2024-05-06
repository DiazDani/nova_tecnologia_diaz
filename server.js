import express from 'express';
import cors from 'cors';
import axios from 'axios';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());

// Función para obtener los ataques de un Pokémon de la primera generación
async function getFirstGenMoves(pokemonName) {
    try {
        const response = await axios.get(`https://pokeapi.co/api/v2/pokemon/${pokemonName}`);
        const moves = response.data.moves;
        const firstGenMoves = moves.filter(move => {
            const version = move.version_group_details[0].version_group.name;
            return version === 'red-blue' || version === 'yellow';
        }).map(move => move.move.name);
        return firstGenMoves;
    } catch (error) {
        throw error;
    }
}

// Ruta para obtener los datos de la PokéAPI
app.get('/pokemons', async (req, res) => {
    try {
        // Realizar la llamada a la PokéAPI
        const response = await axios.get('https://pokeapi.co/api/v2/pokemon?limit=151');
        const data = response.data;
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Ruta para obtener los datos de un Pokémon y sus movimientos de la primera generación
app.get('/pokemons/:name', async (req, res) => {
    try {
        const { name } = req.params;
        // Obtener los datos básicos del Pokémon
        const pokemonDataResponse = await axios.get(`https://pokeapi.co/api/v2/pokemon/${name}`);
        const pokemonData = pokemonDataResponse.data;
        // Obtener los movimientos de la primera generación del Pokémon
        const firstGenMoves = await getFirstGenMoves(name);
        res.json({ pokemonData, firstGenMoves });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`Servidor intermedio escuchando en el puerto ${PORT}`);
});
