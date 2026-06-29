function getDashboardOverview() {
  return {
    stats: [
      { label: 'Nguoi dung', value: '1,248', hint: '+12 hom nay' },
      { label: 'Mon an', value: '386', hint: '12 cho duyet' },
      { label: 'Bai viet', value: '2,164', hint: '18 moi hom nay' },
      { label: 'Tinh thanh', value: '63', hint: '6 vung du lieu' },
    ],
    tasks: [
      'Dung shell admin va navigation chung',
      'Tach users thanh module dau tien',
      'Chuan hoa API response va validate',
    ],
  };
}

module.exports = { getDashboardOverview };
