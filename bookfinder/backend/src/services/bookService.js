const axios = require('axios');
const { normalizeSearchResults, normalizeBookDetails, normalizeSubjectResults } = require('../utils/normalize');

const OPEN_LIBRARY_BASE = 'https://openlibrary.org';
const SEARCH_URL = `${OPEN_LIBRARY_BASE}/search.json`;
const WORKS_URL = `${OPEN_LIBRARY_BASE}/works`;

const axiosInstance = axios.create({
  timeout: 10000,
  headers: {
    'User-Agent': 'BookFinder/1.0 (Academic Project)'
  }
});

// Dedicated client for subject queries. Open Library's subject API can be very
// slow for large categories (e.g. "fiction"), so we allow a longer timeout and
// retry a couple of times before giving up.
const subjectClient = axios.create({
  timeout: 20000,
  headers: {
    'User-Agent': 'BookFinder/1.0 (Academic Project)'
  }
});

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function searchBooks(query, page = 1, limit = 20) {
  const response = await axiosInstance.get(SEARCH_URL, {
    params: {
      q: query,
      page,
      limit,
      fields: 'key,title,author_name,first_publish_year,cover_i,edition_count,subject,isbn,ratings_average,ratings_count,want_to_read_count,currently_reading_count,already_read_count'
    }
  });

  return normalizeSearchResults(response.data, query, page);
}

async function getBookDetails(workId) {
  const cleanId = workId.replace('/works/', '');
  const workUrl = `${OPEN_LIBRARY_BASE}/works/${cleanId}.json`;
  const editionsUrl = `${OPEN_LIBRARY_BASE}/works/${cleanId}/editions.json`;
  const ratingsUrl = `${OPEN_LIBRARY_BASE}/works/${cleanId}/ratings.json`;
  
  const [workRes, editionsRes, ratingsRes] = await Promise.allSettled([
    axiosInstance.get(workUrl),
    axiosInstance.get(editionsUrl, {
      params: { limit: 5, fields: 'key,title,cover_i,isbn,publish_date,number_of_pages,publisher' }
    }),
    axiosInstance.get(ratingsUrl)
  ]);

  if (workRes.status === 'rejected') {
    throw workRes.reason;
  }

  return normalizeBookDetails(
    workRes.value.data,
    editionsRes.status === 'fulfilled' ? editionsRes.value.data : null,
    ratingsRes.status === 'fulfilled' ? ratingsRes.value.data : null
  );
}

async function getTrendingBooks(limit = 10) {
  const response = await axiosInstance.get(`${OPEN_LIBRARY_BASE}/trending/daily.json`, {
    params: { limit }
  });

  const works = response.data.works || [];
  return works.map(doc => ({
    id: doc.key,
    title: doc.title || 'Unknown Title',
    authors: doc.author_name || [],
    first_publish_year: doc.first_publish_year || null,
    cover_id: doc.cover_i || null,
    edition_count: doc.edition_count || null,
    subjects: doc.subject ? doc.subject.slice(0, 5) : [],
    ratings_average: doc.ratings_average || null,
    ratings_count: doc.ratings_count || null,
    want_to_read_count: doc.want_to_read_count || null,
    currently_reading_count: doc.currently_reading_count || null,
    already_read_count: doc.already_read_count || null,
  }));
}

async function getBooksBySubject(subject, page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const url = `${OPEN_LIBRARY_BASE}/subjects/${encodeURIComponent(subject.toLowerCase())}.json`;

  let lastError;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const response = await subjectClient.get(url, {
        params: { limit, offset }
      });
      return normalizeSubjectResults(response.data, subject, page, limit);
    } catch (error) {
      lastError = error;
      if (attempt < 3) {
        await sleep(1000 * attempt);
      }
    }
  }

  throw new Error(
    `Could not load books for "${subject}". The book catalogue may be busy — please try again.`
  );
}

const CATEGORY_DEFS = [
  { name: 'Fiction', subject: 'fiction', emoji: '\u{1F4D6}' },
  { name: 'Science', subject: 'science', emoji: '\u{1F52C}' },
  { name: 'History', subject: 'history', emoji: '\u{1F3DB}' },
  { name: 'Romance', subject: 'romance', emoji: '\u{1F495}' },
  { name: 'Mystery', subject: 'mystery', emoji: '\u{1F50D}' },
  { name: 'Fantasy', subject: 'fantasy', emoji: '\u{1F409}' },
  { name: 'Biography', subject: 'biography', emoji: '\u{1F464}' },
  { name: 'Self-Help', subject: 'self-help', emoji: '\u{1F31F}' },
  { name: 'Technology', subject: 'technology', emoji: '\u{1F4BB}' },
  { name: 'Art', subject: 'art', emoji: '\u{1F3A8}' },
  { name: 'Poetry', subject: 'poetry', emoji: '\u270D' },
  { name: 'Thriller', subject: 'thriller', emoji: '\u{1F631}' },
  { name: 'Philosophy', subject: 'philosophy', emoji: '\u{1F914}' },
  { name: 'Travel', subject: 'travel', emoji: '\u2708' },
  { name: 'Comics', subject: 'comics', emoji: '\u{1F4AC}' },
  { name: 'Horror', subject: 'horror', emoji: '\u{1F47B}' },
];

async function getCategories() {
  const results = await Promise.allSettled(
    CATEGORY_DEFS.map(cat =>
      axiosInstance
        .get(`${OPEN_LIBRARY_BASE}/subjects/${cat.subject}.json`, {
          params: { limit: 1 },
          timeout: 6000,
        })
        .then(res => res.data.work_count || 0)
        .catch(() => 0)
    )
  );

  const categories = CATEGORY_DEFS.map((cat, index) => ({
    name: cat.name,
    subject: cat.subject,
    emoji: cat.emoji,
    bookCount: results[index].status === 'fulfilled' ? results[index].value : 0,
  }));

  const total = categories.reduce((sum, c) => sum + c.bookCount, 0);
  categories.forEach(c => {
    c.percentage = total > 0 ? Number(((c.bookCount / total) * 100).toFixed(1)) : 0;
  });

  return categories.sort((a, b) => b.bookCount - a.bookCount);
}

async function getRecommendations(limit = 10) {
  const [trendingRes, fictionRes, scienceRes] = await Promise.allSettled([
    axiosInstance.get(`${OPEN_LIBRARY_BASE}/trending/daily.json`, { params: { limit: Math.ceil(limit / 2) } }),
    subjectClient.get(`${OPEN_LIBRARY_BASE}/subjects/fiction.json`, { params: { limit: Math.ceil(limit / 3) } }),
    subjectClient.get(`${OPEN_LIBRARY_BASE}/subjects/science.json`, { params: { limit: Math.ceil(limit / 3) } }),
  ]);

  const seen = new Set();
  const recommendations = [];

  const pushBook = (doc, reason) => {
    const id = doc.key;
    if (!id || seen.has(id)) return;
    seen.add(id);
    recommendations.push({
      id,
      title: doc.title || 'Unknown Title',
      authors: doc.author_name
        ? doc.author_name.slice(0, 2)
        : doc.authors
          ? doc.authors.map(a => a.name).slice(0, 2)
          : [],
      first_publish_year: doc.first_publish_year || null,
      cover_id: doc.cover_i || doc.cover_id || null,
      edition_count: doc.edition_count || null,
      subjects: doc.subject ? doc.subject.slice(0, 5) : [],
      ratings_average: doc.ratings_average || null,
      ratings_count: doc.ratings_count || null,
      want_to_read_count: doc.want_to_read_count || null,
      reason,
    });
  };

  if (trendingRes.status === 'fulfilled') {
    (trendingRes.value.data.works || []).forEach(doc => pushBook(doc, 'Trending now'));
  }
  if (fictionRes.status === 'fulfilled') {
    (fictionRes.value.data.works || []).forEach(doc => pushBook(doc, 'Popular in Fiction'));
  }
  if (scienceRes.status === 'fulfilled') {
    (scienceRes.value.data.works || []).forEach(doc => pushBook(doc, 'Popular in Science'));
  }

  return recommendations.slice(0, limit);
}

module.exports = {
  searchBooks,
  getBookDetails,
  getTrendingBooks,
  getBooksBySubject,
  getCategories,
  getRecommendations
};