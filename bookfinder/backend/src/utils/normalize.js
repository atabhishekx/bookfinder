function normalizeSearchResults(data, query, page) {
  const docs = data.docs || [];
  const results = docs.map(doc => ({
    id: doc.key,
    title: doc.title || 'Unknown Title',
    authors: doc.author_name || [],
    first_publish_year: doc.first_publish_year || null,
    cover_id: doc.cover_i || null,
    edition_count: doc.edition_count || null,
    subjects: doc.subject ? doc.subject.slice(0, 10) : [],
    isbn: doc.isbn ? doc.isbn.slice(0, 5) : [],
    ratings_average: doc.ratings_average || null,
    ratings_count: doc.ratings_count || null,
    want_to_read_count: doc.want_to_read_count || null,
    currently_reading_count: doc.currently_reading_count || null,
    already_read_count: doc.already_read_count || null,
  }));

  return {
    query,
    page,
    total: data.numFound || 0,
    results
  };
}

function normalizeBookDetails(workData, editionsData, ratingsData) {
  const work = workData;
  const editions = editionsData?.entries || [];

  let description = null;
  if (work.description) {
    description = typeof work.description === 'string'
      ? work.description
      : work.description.value;
  }

  let coverId = null;
  if (work.covers && work.covers.length > 0) {
    coverId = work.covers[0];
  } else if (editions.length > 0 && editions[0].covers && editions[0].covers.length > 0) {
    coverId = editions[0].covers[0];
  }

  const subjects = work.subjects || [];
  const authors = (work.authors || [])
    .map(a => a.author?.key ? a.author.key.split('/').pop() : null)
    .filter(Boolean);

  const firstPublishDate = work.first_publish_date
    ? new Date(work.first_publish_date).getFullYear()
    : (work.created?.value ? new Date(work.created.value).getFullYear() : null);

  const ratings = ratingsData ? {
    average: ratingsData.summary?.average || null,
    count: ratingsData.summary?.count || null,
  } : null;

  return {
    id: work.key,
    title: work.title || 'Unknown Title',
    authors,
    first_publish_year: firstPublishDate,
    cover_id: coverId,
    description: description ? description.slice(0, 2000) : null,
    subjects: subjects.slice(0, 20),
    edition_count: work.edition_count || editions.length || null,
    ratings_average: ratings?.average || null,
    ratings_count: ratings?.count || null,
    edition_details: editions.map(e => ({
      key: e.key,
      title: e.title,
      cover_id: e.covers?.[0] || null,
      isbn: e.isbn?.[0] || null,
      publish_date: e.publish_date?.[0] || null,
      number_of_pages: e.number_of_pages || null,
      publisher: e.publisher?.[0] || null
    })).slice(0, 5)
  };
}

function normalizeSubjectResults(data, subject, page, limit) {
  const works = data.works || [];
  const results = works.map(doc => ({
    id: doc.key,
    title: doc.title || 'Unknown Title',
    authors: doc.authors ? doc.authors.map(a => a.name) : [],
    first_publish_year: doc.first_publish_year || null,
    cover_id: doc.cover_id || null,
    edition_count: doc.edition_count || null,
    subjects: doc.subject ? doc.subject.slice(0, 10) : [],
  }));

  return {
    query: subject,
    page,
    total: data.work_count || 0,
    results
  };
}

function getCoverUrl(coverId, size = 'M') {
  if (!coverId) return null;
  return `https://covers.openlibrary.org/b/id/${coverId}-${size}.jpg`;
}

module.exports = {
  normalizeSearchResults,
  normalizeBookDetails,
  normalizeSubjectResults,
  getCoverUrl
};