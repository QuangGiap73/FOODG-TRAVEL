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
// hàm cập nhật món ăn 
async function updateDish(req, res) {
    try {
        const id = req.params.id; // lay id mon an
        if(!id) {
            return res.status(400).json({error: 'Missing id'});
        }
        // lay du lieu moi ve
        const payload = req.body || {};
        // ghi du lieu 
        await db 
            .collection('dishes')
            .doc(id)
            .set(payload, { merge: true});
        res.json({ success: true});
    } catch (err) {
        console.error('updateDish error',err);
        res.status(500).json({error: 'Failed to update dish'});
    }
    
}
// hàm xóa 
async function deleteDish(req, res) {
    try {
        const id = req.params.id;
        if(!id) return res.status(400).json({error: 'Missing id'});
        await db.collection('dishes').doc(id).delete();
        res.json({ success:true});
    } catch (err) {
        console.error('deleteDish error',err);
        res.status(500).json({ error: 'Failed to delete dish'});
    }
    
}
// hàm thêm món ăn 
async function createDish(req, res){
    try {
        // lay du lieu tu frontend
        const payload = req.body || {};
        if(!payload.id || !payload.Name){
            return res.status(400).json({ error:'Missing id or name'});
        }
        // ghi du lieu len firebase
        await db.collection('dishes')
            .doc(payload.id)
            .set(payload, {merge: false});
            res.json({success: true});
    } catch (err){
        console.error('createDisnh error,err', err);
        res.status(500).json({error:'Failed to create dish'});
    }
}
module.exports = {
    renderDishesPage,
    listDishes,
    updateDish,
    deleteDish,
    createDish
};