import express from 'express';
import cors from 'cors';
import axios from 'axios';

const app = express();
const PORT = process.env.PORT || 3080;

app.use(cors());

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

app.get('/pokemons', async (req, res) => {
    try {
        const response = await axios.get('https://pokeapi.co/api/v2/pokemon?limit=151');
        const data = response.data;
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Route to get data of a Pokémon and its first generation moves
app.get('/pokemons/:name', async (req, res) => {
    try {
        const { name } = req.params;
        const pokemonDataResponse = await axios.get(`https://pokeapi.co/api/v2/pokemon/${name}`);
        const pokemonData = pokemonDataResponse.data;
        // Get first generation moves of the Pokémon
        const firstGenMoves = await getFirstGenMoves(name);
        res.json({ pokemonData, firstGenMoves });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`server listening on port ${PORT}`);
});
