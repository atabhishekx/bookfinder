const express = require('express');
const router = express.Router();
const bookService = require('../services/bookService');

router.get('/search', async (req, res, next) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;

    if (!q || !q.trim()) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Query parameter "q" is required and cannot be empty'
      });
    }

    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));

    const result = await bookService.searchBooks(q.trim(), pageNum, limitNum);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

router.get('/trending', async (req, res, next) => {
  try {
    const { limit = 10 } = req.query;
    const limitNum = Math.min(20, Math.max(1, parseInt(limit, 10) || 10));
    const books = await bookService.getTrendingBooks(limitNum);
    res.json({ results: books, total: books.length });
  } catch (error) {
    next(error);
  }
});

router.get('/subject/:subject', async (req, res, next) => {
  try {
    const { subject } = req.params;
    const { page = 1, limit = 20 } = req.query;

    if (!subject || !subject.trim()) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Subject parameter is required'
      });
    }

    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));

    const result = await bookService.getBooksBySubject(subject.trim(), pageNum, limitNum);
    res.json(result);
  } catch (error) {
    // Return a clean, user-friendly error instead of a raw 500 stack trace.
    // The upstream (Open Library) subject API is often slow for large categories.
    res.status(502).json({
      error: 'Upstream error',
      message: error.message || 'Could not load books for this category. Please try again.'
    });
  }
});

router.get('/categories', async (req, res, next) => {
  try {
    const categories = await bookService.getCategories();
    res.json({ categories, total: categories.length });
  } catch (error) {
    next(error);
  }
});

router.get('/recommendations', async (req, res, next) => {
  try {
    const { limit = 10 } = req.query;
    const limitNum = Math.min(20, Math.max(1, parseInt(limit, 10) || 10));
    const books = await bookService.getRecommendations(limitNum);
    res.json({ results: books, total: books.length });
  } catch (error) {
    next(error);
  }
});

router.get('/:workId', async (req, res, next) => {
  try {
    const { workId } = req.params;

    if (!workId || !workId.trim()) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Work ID is required'
      });
    }

    const book = await bookService.getBookDetails(workId.trim());

    if (!book) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Book not found'
      });
    }

    res.json(book);
  } catch (error) {
    next(error);
  }
});

module.exports = router;