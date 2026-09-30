# Two-minute demo script

Before recording, make the terminal text large enough to read and run `./app.sh`.

1. **Introduce the system (15 seconds).**
   “This is Stories & Spaces, my personal command-line book manager for romance, mystery, photography, art, and interior design. It is built from small Bash programs arranged into UI, workflow, component, data, and storage layers.”

2. **Browse and search (25 seconds).**
   Open **Browse Library**, point out that the initial books are an unrated want-to-read shelf, then search for `photography`.
   “The search term moves from the UI into the library workflow and search component. Only the database layer touches the CSV file.”

3. **Add or update a book (30 seconds).**
   Add `Photo Finished` by `Christin Brecher`, or update an existing book’s status.
   “Known books are enriched from a small offline catalog, then the workflow asks the database layer to save the structured record.”

4. **Generate recommendations (40 seconds).**
   Select **Get Recommendations** and pause on the running/done indicators.
   “Three independent agents run at the same time: one follows my saved books, one uses my interests in romance, mystery, photography, art, and interior design, and one looks for creative crossovers. Bash process IDs and `wait` synchronize them. Their outputs are piped through a refinement component that removes duplicates and books I already have.”

5. **Save and close (10 seconds).**
   Save one recommendation and browse the library to show it under `want-to-read`.
   “The final choice flows back through the library workflow into storage. The whole application stays small enough that I can explain every file.”
