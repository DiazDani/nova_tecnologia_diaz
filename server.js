import express from 'express';
import cors from 'cors';
import axios from 'axios';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());

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

app.listen(PORT, () => {
    console.log(`Servidor intermedio escuchando en el puerto ${PORT}`);
});
