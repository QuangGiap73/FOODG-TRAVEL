function toUserCard(user) {
  return {
    id: user.id,
    title: user.fullName,
    subtitle: user.email,
    badge: user.role,
  };
}

function toUserViewModel(doc) {
  return {
    id: doc.id,
    email: doc.email || '',
    fullName: doc.fullName || '',
    phone: doc.phone || '',
    photoUrl: doc.photoUrl || '',
    gender: doc.gender || null,
    dateOfBirth: doc.dateOfBirth || null,
    onboardingCompleted: Boolean(doc.onboardingCompleted),
    preferences: doc.preferences || null,
    journeySummary: doc.journeySummary || null,
    recentCheckins: Array.isArray(doc.recentCheckins) ? doc.recentCheckins : [],
    badges: Array.isArray(doc.badges) ? doc.badges : [],
    recentPosts: Array.isArray(doc.recentPosts) ? doc.recentPosts : [],
    role: doc.role || 'user',
    authUid: doc.authUid || doc.id,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

module.exports = { toUserCard, toUserViewModel };
