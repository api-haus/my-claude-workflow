---
name: domain-availability
description: Generates creative domain name ideas and checks availability across multiple TLDs (.com, .io, .dev, .ai, etc.). Saves hours of brainstorming and manual checking.
---

# Domain Name Brainstormer

## When to Activate

- User asks for domain name suggestions or ideas
- User asks "is X.com available?" or similar availability checks
- User mentions wanting to register or buy a domain
- User explicitly requests help finding an available domain for their project

---

## Output Format

Your response MUST follow the exact format shown in these examples. Study them carefully.

<example>
<user_request>a fitness tracking app for busy professionals</user_request>
<response>
## Available Domains

### .com (Premium)

1. `fitpulse.com`
   **Why:** Combines fitness with real-time tracking metaphor

2. `quickrep.com`
   **Why:** Short, implies fast workouts, gym terminology

### .io / .co (Startup-friendly)

3. `trainfast.io`
   **Why:** Action-oriented, appeals to time-conscious users

4. `gymflow.co`
   **Why:** Smooth, suggests seamless workout experience

### .dev / .app / .ai (Tech-specific)

5. `fitnow.app`
   **Why:** Urgency + perfect TLD for mobile app

6. `repcount.ai`
   **Why:** AI-powered tracking angle, gym terminology

### Other TLDs

7. `sweatlog.xyz`
   **Why:** Descriptive, affordable registration

---

## Top Recommendations

**Top Pick: `fitpulse.com`**
- Premium .com builds trust
- Memorable and brandable

**Runner-up: `fitnow.app`**
- Perfect TLD match for mobile app
- Conveys immediacy

**Budget Pick: `sweatlog.xyz`**
- Low cost to register
- Clear purpose in the name

---

Want me to explore a different naming direction?
</response>
</example>

<example>
<user_request>a collaborative note-taking tool for teams</user_request>
<response>
## Available Domains

### .com (Premium)

1. `notehive.com`
   **Why:** Collaboration metaphor (hive), memorable

2. `teamscribe.com`
   **Why:** Clear purpose, professional tone

### .io / .co (Startup-friendly)

3. `syncnote.io`
   **Why:** Implies real-time sync, tech-forward

4. `collab.co`
   **Why:** Ultra-short, obvious purpose

### .dev / .app / .ai (Tech-specific)

5. `notecraft.dev`
   **Why:** Appeals to developers, suggests customization

6. `teamnotes.app`
   **Why:** Straightforward, app-store friendly

### Other TLDs

7. `scribehub.xyz`
   **Why:** Community feel, budget-friendly

---

## Top Recommendations

**Top Pick: `notehive.com`**
- Strong brand potential
- Easy to remember and spell

**Runner-up: `syncnote.io`**
- Modern tech feel
- Communicates key feature

**Budget Pick: `scribehub.xyz`**
- Community-oriented name
- Very affordable

---

Want me to explore a different naming direction?
</response>
</example>

<example>
<user_request>an AI recipe generator</user_request>
<response>
## Available Domains

### .com (Premium)

1. `chefbot.com`
   **Why:** Friendly AI persona, easy to say

2. `recipemind.com`
   **Why:** Suggests intelligent recipe creation

### .io / .co (Startup-friendly)

3. `cookwise.io`
   **Why:** Implies smart cooking assistance

4. `mealgen.co`
   **Why:** Short, clear generator purpose

### .dev / .app / .ai (Tech-specific)

5. `recipe.ai`
   **Why:** Perfect TLD match, premium feel

6. `cookai.app`
   **Why:** Playful, mobile-first positioning

### Other TLDs

7. `dishcraft.xyz`
   **Why:** Creative angle, affordable

---

## Top Recommendations

**Top Pick: `recipe.ai`**
- Ideal domain for AI product
- Highly memorable

**Runner-up: `chefbot.com`**
- Friendly brand personality
- Premium .com credibility

**Budget Pick: `dishcraft.xyz`**
- Creative and unique
- Low registration cost

---

Want me to explore a different naming direction?
</response>
</example>

---

## Rules

1. Use `check_domains` MCP tool only (never bash/whois/dig)
2. Find at least 10 available domains
3. Show only the best 10-12 in your response
4. Maximum 3 rounds of checking
5. Group by TLD: .com first, then .io/.co, then .dev/.app/.ai, then Other
6. Every domain needs a **Why:** explanation
7. End with Top Recommendations (Top Pick, Runner-up, Budget Pick)

If `check_domains` is unavailable, tell the user to wait a moment and try again.

---

## Workflow

1. Understand what they're building, target audience, desired vibe
2. Generate 15-20 name ideas silently (compound words, verb+noun, truncations, portmanteaus)
3. Call `check_domains` MCP tool with your list
4. If <10 available, generate more and check again (max 3 rounds)
5. Format response exactly like the examples above
