# Stories & Spaces

Stories & Spaces is a personal terminal application centered on romantic and mystery fiction, photography, art, and interior design. It tracks a small library, enriches known titles from an offline catalog, searches books, updates reading progress and ratings, and produces a ranked recommendation shortlist from three concurrent strategies.

## Run it

The application uses Bash and [Gum](https://github.com/charmbracelet/gum) for its interactive interface.

```bash
brew install gum
chmod +x app.sh
./app.sh
```

If Gum is not installed, the application still provides a portable numbered menu. Gum is recommended for the intended experience.

The starter library is in `data/books.csv`. Edit `data/interests.txt` directly, or select **Edit Interests** in the application. Run the automated checks with:

```bash
./tests/run_tests.sh
```

## Architecture

The application follows `UI → Workflows → Components → Data Layer → Storage`. `app.sh` only initializes storage and opens the main menu. Scripts in `ui/` collect choices and display results; scripts in `workflows/` coordinate complete operations; `books/` and `recommendations/` contain focused book intelligence; and `data/book_database.sh` is the only application component that reads or writes `data/books.csv`. Every component exchanges predictable pipe-delimited text, which keeps the data flow visible and testable.

The recommendation workflow launches history, interest, and discovery agents in the background with `&`, records each `$!` process ID, streams status messages, and synchronizes with `wait`. Their outputs are composed through a real pipeline:

```bash
cat history.txt interests.txt discovery.txt \
  | recommendations/refine_recommendations.sh \
  > final.txt
```

The refinement component removes duplicates and books already in the library, ranks candidates, and returns five results.

## Personalization

Stories & Spaces is tuned around romance, mystery, photography, visual art, and interior design. The starter library is an unrated `want-to-read` shelf rather than an invented reading history. The history agent follows books the user actually saves, the interest agent matches an editable topic profile, and the discovery agent finds crossovers such as art crime, literary mystery, and visually rich fiction. The useful extra feature is a save loop: one recommendation can be added directly to the `want-to-read` list. All metadata and recommendations are deterministic and offline so the project remains fast, understandable, and reliable during a demo.

## Key commands

The interface supports:

- browsing and searching the library;
- adding a book with local metadata enrichment;
- updating reading status and rating;
- editing recommendation interests;
- running three recommendation agents in parallel;
- saving a recommended book to the library.

Individual components are also usable from the terminal:

```bash
echo "technology" | ./books/search_books.sh
echo "Rebecca|Daphne du Maurier" | ./books/fetch_book_metadata.sh
BOOK_MANAGER_AGENT_DELAY=0 ./workflows/get_recommendations.sh --non-interactive
```

## Demo video

Record a short narrated terminal demo before submission and add the video file or link here. A concise narration and shot list are provided in [`DEMO_SCRIPT.md`](DEMO_SCRIPT.md).

**Demo video:** _Add link before submission._
