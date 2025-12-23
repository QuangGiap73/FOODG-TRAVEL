document.addEventListener('DOMContentLoaded', () =>{
    // lấy render dữ liệu món ăn
    const tbody = document.getElementById('dish-table-body');
    const searchInput = document.getElementById('dish-search');// o tìm kiếm
    const btnSearch = document.getElementById('btn-search-dish'); // nút tìm kiếm
    const btnReset = document.getElementById('btn-reset-dish'); // nút reset

    // hàm load danh sách 
    async function loadDishes() {
        if(!tbody) return;
        const q = encodeURIComponent((searchInput?.value || '').trim());
        // hiển thi trang thái đang tải dữ liệu
        tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted">Dang tai...</td></tr>';
        try {
            // gọi api để lấy danh sách món ăn 
            const res = await fetch(`/manager-dishes/api/dishes?q=${q}`);

            // lỗi thì trả rỗng
            const body = await res.json().catch(() => ({}));
            if (!res.ok) throw new Error(body.error || 'tai mon that bai');
            // đảm bảo dữ liệu là mảng 
            const list = Array.isArray(body.data) ? body.data : [];
            renderTable(list); // render dữ liệu ra bảng
        } catch (err) {
            console.error(err);
            tbody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">${err.message || 'Loi tai du lieu'}</td></tr>`;
        }
    }
    // hàm render bảng món ăn
    function renderTable(list) {
        if (!list.length) {
          tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">Chua co du lieu</td></tr>';
          return;
        }
        tbody.innerHTML = list
          .map((item, idx) => {
            const img = item.Img || item.img || item.imageUrl || '';
            const name = item.Name || item.name || '';
            const slug = item.slug || '';
            const region = item.region_code || '';
            const province = item.province_code || '';
            const cat = item.category || '';
            const price = item.price_range || '';
            const spicy = item.spicy_level != null ? item.spicy_level : '';
            const satiety = item.satiety_level != null ? item.satiety_level : '';
            const bestTime = item.Best_time || item.best_time || '';
            const bestSeason = item.Best_season || item.best_season || '';
            const tags = item.Tags || item.tags || '';
            const rowNum = item.STT || idx + 1;
    
            return `
            <tr>
              <td class="text-muted small">${rowNum}</td>
              <td style="width:70px;">
                ${
                  img
                    ? `<img src="${img}" alt="" style="width:56px;height:56px;object-fit:cover;border-radius:6px;">`
                    : `<div style="width:56px;height:56px;border-radius:6px;background:#f4f6f8;display:flex;align-items:center;justify-content:center;" class="text-muted small">N/A</div>`
                }
              </td>
              <td>
                <div class="fw-semibold">${name}</div>
                <div class="text-muted small">${slug}</div>
                ${tags ? `<div class="text-muted small">${tags}</div>` : ''}
              </td>
              <td>
                <div>${province || '-'}</div>
                <div class="text-muted small">${region || ''}</div>
              </td>
              <td>${cat || ''}</td>
              <td>
                ${price || ''}
                ${bestTime ? `<div class="text-muted small">Time: ${bestTime}</div>` : ''}
                ${bestSeason ? `<div class="text-muted small">Season: ${bestSeason}</div>` : ''}
              </td>
              <td>
                <div>Spicy: ${spicy}</div>
                <div class="text-muted small">No: ${satiety}</div>
              </td>
            </tr>
          `;
          })
          .join('');
      }
    
      btnSearch?.addEventListener('click', loadDishes);
      btnReset?.addEventListener('click', () => {
        if (searchInput) searchInput.value = '';
        loadDishes();
      });
      searchInput?.addEventListener('keyup', (e) => {
        if (e.key === 'Enter') loadDishes();
      });
    
      loadDishes();
});