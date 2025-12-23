const { db } = require('../firebase/config');

function renderDishesPage(req, res){
    res.render('manager_dishes/manager_dishes', { pageTitle: 'Quan ly mon an'});
}

// chuc nang lay danh sach
async function listDishes(req, res) {
    try{
        // lay tu khoa tim kiem
        const q = (req.query.q || '').trim().toLowerCase();
        const snap = await db.collection('dishes').get(); // lay du lieu dish
        let dishes = snap.docs.map((d) => ({id: d.id, ...d.data()})); // chuyen doi du lieu

        if(q) {
            dishes = dishes.filter((item) =>{ // loc danh sach
                const name = String(item.name || item.Name || '').toLowerCase();
                const slug = String(item.slug || '').toLowerCase();
                return name.includes(q) || slug.includes(q); // dieu kien co chua tu khoa 

            });
        }
        res.json({data: dishes});
    }catch (err) {
        console.error('listDishes error', err);
        res.status(500).json({error: 'Failed to load dishes'});
    }
    
}
module.exports = {
    renderDishesPage,
    listDishes
};