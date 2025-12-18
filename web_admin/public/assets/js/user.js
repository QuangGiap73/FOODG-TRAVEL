// chức năng xuất file excel
document.getElementById('exportExcelBtn').addEventListener('click', () => {
  const url = new URL(window.location.href);
  const sort = url.searchParams.get('sort');
  let exportUrl = '/user/export-excel';
  if (sort) exportUrl += `?sort=${sort}`;
  window.location.href = exportUrl;
});




// scrip chức năng bấm nút xóa của mỗi tài khoản
document.addEventListener('DOMContentLoaded', () => {
  const deleteButtons = document.querySelectorAll('.btn-delete-user');

  deleteButtons.forEach(button => {
    button.addEventListener('click', function (e) {
      e.preventDefault();

      const userId = this.dataset.id;
      const userName = this.dataset.name;

      Swal.fire({
        title: `Xác nhận xóa`,
        text: `Bạn có chắc chắn muốn xóa người dùng "${userName}"?`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#3085d6',
        confirmButtonText: 'Xóa',
        cancelButtonText: 'Hủy'
      }).then((result) => {
        if (result.isConfirmed) {
          const form = document.createElement('form');
          form.method = 'POST';
          form.action = `/user/delete/${userId}`;

          // Nếu có csrfToken, thêm input vào form
          if (typeof csrfToken !== 'undefined' && csrfToken !== '') {
            const csrfInput = document.createElement('input');
            csrfInput.type = 'hidden';
            csrfInput.name = '_csrf';
            csrfInput.value = csrfToken;
            form.appendChild(csrfInput);
          }

          document.body.appendChild(form);
          form.submit();
        }
      });
    });
  });
});



