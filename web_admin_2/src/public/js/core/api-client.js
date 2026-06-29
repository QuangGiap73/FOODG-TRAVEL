async function apiGet(url) {
  const response = await fetch(url);
  return response.json();
}

window.apiGet = apiGet;
