# Learning System: Amp CLI vs Claude Code CLI

## 🎯 The Core Question

**"How do future iterations learn from previous mistakes when each iteration is a fresh AI instance with no memory?"**

---

## ❌ Amp CLI Approach: Thread URLs

### How It Works
```
Iteration 1 completes → Thread URL: https://ampcode.com/threads/abc123
                     ↓
              Logs to progress.txt:
              "Thread: https://ampcode.com/threads/abc123"
                     ↓
Iteration 2 starts → Reads progress.txt
                  → Sees thread URL
                  → Uses read_thread tool
                  → Reads entire conversation from Iteration 1
                  → Learns from conversation context
```

### Pros
- ✅ Full conversation context
- ✅ Can see reasoning process
- ✅ Automatic by Amp CLI

### Cons
- ❌ Requires external service (Amp servers)
- ❌ Not searchable locally
- ❌ Conversational (hard to scan)
- ❌ No consolidation of learnings
- ❌ Service dependency
- ❌ Not version controlled
- ❌ Requires internet

---

## ✅ Claude Code CLI Approach: Structured File-Based Learning

### How It Works
```
Iteration 1 completes → Commit code (hash: a1b2c3d)
                     ↓
              Documents in progress.txt:
              ┌────────────────────────────────┐
              │ Commit: a1b2c3d                │
              │ Files: player-page.tsx (+45)   │
              │                                │
              │ Patterns discovered:           │
              │ - Use SmartDataView component  │
              │ - Use useSearchParams for URL  │
              │                                │
              │ Gotchas:                       │
              │ - Must debounce search input   │
              │                                │
              │ Mistakes made:                 │
              │ - Initially used .filter()     │
              │   instead of .withIndex()      │
              └────────────────────────────────┘
                     ↓
              Updates Codebase Patterns section:
              ┌────────────────────────────────┐
              │ ## Codebase Patterns           │
              │                                │
              │ - Use SmartDataView for tables │
              │ - Use .withIndex() not filter()│
              │ - Debounce search inputs       │
              └────────────────────────────────┘
                     ↓
Iteration 2 starts → Reads Codebase Patterns FIRST
                  → Reads Iteration 1's entry
                  → Runs: git show a1b2c3d
                  → Sees exact code changes
                  → Avoids .filter() mistake
                  → Uses SmartDataView
                  → Adds debounce from start
```

### Pros
- ✅ Structured and scannable (Codebase Patterns section)
- ✅ Git-versioned (permanent)
- ✅ Offline (all local files)
- ✅ Searchable (`grep`)
- ✅ Consolidates knowledge over time
- ✅ Explicit "Mistakes made" section
- ✅ Commit hashes = code examples
- ✅ Actionable next steps for partial stories
- ✅ No external dependencies

### Cons
- ⚠️ Requires disciplined documentation (but prompt enforces this)

---

## 📊 Side-by-Side Comparison

### Scenario: Iteration 2 needs to learn from Iteration 1

#### Amp CLI
```
1. Read progress.txt
2. See: "Thread: https://ampcode.com/threads/abc123"
3. Call: read_thread("abc123")
4. Get: Full conversation transcript
   "I tried using .filter() but got an error..."
   "Oh I see, I need to use .withIndex() instead..."
   "Let me read the file..."
   [20+ messages of back and forth]
5. Parse conversation mentally
6. Extract key learnings
7. Apply to current work
```

**Time**: Slow (read entire conversation)
**Quality**: Variable (must extract patterns from conversation)

#### Claude Code CLI
```
1. Read progress.txt
2. See Codebase Patterns section:
   ┌────────────────────────────────┐
   │ - Use .withIndex() not filter()│
   │ - Use SmartDataView for tables │
   │ - Debounce search inputs       │
   └────────────────────────────────┘
3. See Iteration 1 entry:
   ┌────────────────────────────────┐
   │ Mistakes made:                 │
   │ - Used .filter() → error       │
   │   Solution: use .withIndex()   │
   │                                │
   │ Commit: a1b2c3d                │
   └────────────────────────────────┘
4. Run: git show a1b2c3d
5. See exact code implementation
6. Apply learnings immediately
```

**Time**: Fast (structured summary)
**Quality**: High (explicit patterns + code examples)

---

## 🔄 Learning Accumulation Over Time

### Amp CLI (Thread URLs)
```
Iteration 1: Thread URL abc
Iteration 2: Thread URL def
Iteration 3: Thread URL ghi
Iteration 4: Thread URL jkl

To learn everything, Iteration 5 must:
- Read thread abc
- Read thread def
- Read thread ghi
- Read thread jkl

Knowledge is DISTRIBUTED across threads
```

### Claude Code CLI (Codebase Patterns)
```
Iteration 1: Discovers pattern → Adds to Codebase Patterns
Iteration 2: Discovers pattern → Adds to Codebase Patterns
Iteration 3: Discovers pattern → Adds to Codebase Patterns
Iteration 4: Discovers pattern → Adds to Codebase Patterns

To learn everything, Iteration 5:
- Reads Codebase Patterns section (one place!)

Knowledge is CONSOLIDATED at the top
```

---

## 💡 Real Example

### Iteration 1: Learning About Player Data

#### Amp CLI progress.txt
```
## Iteration 1
Thread: https://ampcode.com/threads/abc123
- Implemented player search
- Works well
```

**Iteration 2 reads thread abc123:**
> "Let me search for where player data is stored..."
> "I found a players table..."
> "Wait, that's not being used..."
> "Oh I see, the actual data is in orgPlayerEnrollments..."
> "Let me query that instead..."
> "Hmm, I need to filter by organizationId..."
> [10 more messages figuring this out]

#### Claude Code CLI progress.txt
```
## Codebase Patterns
### Data Models
- Player data: orgPlayerEnrollments table (NOT players table)
- Must filter by organizationId for multi-tenancy
- Use index: by_org_and_status

---

## 2026-01-11 15:30 - US-001
**Commit**: a1b2c3d

### Learnings
**Patterns discovered:**
- Player data in orgPlayerEnrollments table
- Players table exists but is legacy/unused
- Always filter by organizationId

**Mistakes made:**
- Initially queried players table (wrong table)
- Forgot organizationId filter (returned all orgs' data)
- Used .filter() instead of .withIndex() (slow query)
```

**Iteration 2 reads Codebase Patterns:**
- ✅ Knows to use orgPlayerEnrollments
- ✅ Knows to filter by organizationId
- ✅ Knows to use .withIndex()
- ✅ Avoids all 3 mistakes

---

## 🎯 Key Advantages of Our Approach

### 1. **Consolidation**
```
Amp: 10 threads with scattered learnings
Ours: 1 Codebase Patterns section with all learnings
```

### 2. **Code Examples**
```
Amp: "I fixed it by changing the query"
Ours: "Commit a1b2c3d shows the exact fix"
       → git show a1b2c3d
       → See actual code
```

### 3. **Explicit Mistakes**
```
Amp: Must infer mistakes from conversation
Ours: "Mistakes made:" section explicitly lists them
```

### 4. **Actionable Next Steps**
```
Amp: "I'll continue this later"
Ours: **What to do next:**
      - [ ] Wire up backend query
      - [ ] Add debounce logic
      - [ ] Test with real data
```

### 5. **Searchability**
```
Amp: Can't search threads locally
Ours: grep "SmartDataView" progress.txt
      → Find all mentions instantly
```

### 6. **Permanence**
```
Amp: Depends on Amp service availability
Ours: Git-versioned, committed with code
```

---

## 📈 Learning Effectiveness Over Iterations

```
Iteration | Amp CLI | Claude Code CLI
----------|---------|----------------
1         | Learns  | Learns + Documents patterns
2         | Re-learns 50% | Applies patterns, learns new
3         | Re-learns 30% | Applies all patterns, learns new
4         | Re-learns 20% | Applies all patterns, learns new
5+        | Still re-learning | Pure new discoveries

Result after 10 iterations:
Amp:   Still discovering basic patterns
Ours:  Advanced knowledge, building on solid foundation
```

---

## 🏆 Winner: Claude Code CLI

Our structured file-based learning system is **superior** to Amp's thread URLs because:

1. ✅ **Faster** - Codebase Patterns is quick reference
2. ✅ **More permanent** - Git-versioned
3. ✅ **More actionable** - Explicit patterns, gotchas, mistakes
4. ✅ **More searchable** - Local grep/search
5. ✅ **More consolidated** - Knowledge accumulates at top
6. ✅ **Code-backed** - Commit hashes + git show
7. ✅ **Offline** - No external dependencies
8. ✅ **Structured** - Scannable format

---

## 🚀 Try It Yourself

When you run Ralph, watch how the Codebase Patterns section grows:

**After Iteration 1:**
```markdown
## Codebase Patterns
- Use SmartDataView for tables
```

**After Iteration 3:**
```markdown
## Codebase Patterns
- Use SmartDataView for tables
- Use .withIndex() not .filter()
- useSearchParams for URL state
- Player data in orgPlayerEnrollments
```

**After Iteration 5:**
```markdown
## Codebase Patterns
- Use SmartDataView for tables
- Use .withIndex() not .filter()
- useSearchParams for URL state
- Player data in orgPlayerEnrollments
- Debounce search inputs (300ms)
- Filter by organizationId always
- Use Better Auth for team queries
```

Each iteration builds on this consolidated knowledge!

---

**Bottom Line**: We don't need thread URLs. Our system is better. 🎯
