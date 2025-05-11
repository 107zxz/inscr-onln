## Contributing to the Project

- Whenever possible, try **not** to hardcode sigils and the like... or anything really. Things are much more useful when non-hardcoded, and un-hardcoding them can be a bit of a pain.
- Whenever possible, provide at least 1 way for the user or call site to customize behavior.
- For the love of all that his holy and/or unholy, please add comments.
- Godot can do some fancy and useful things with comments. I know people haven't been doing it, but it's not too late to start.
    - There is a button called 'Search Help' that allows you to search through such comments.
    - Source: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html

## Style Guide

### Variable Case

variable: `snake_case`  
"private" variable: `_snake_case`  
function: `snake_case`  
virtual function: `_snake_case`  
function argument / `for` iteration variable: `snake_case`  
unused function argument / `for` iteration variable: `_snake_case`  
constant: `SCREAMING_SNAKE_CASE`  
constant Script: `PascalCase`  
enum name: `PascalCase`  
enum key: `SCREAMING_SNAKE_CASE`  
class name: `PascalCase`  
autoload name: `PascalCase`  
file/folder names: `snake_case`  
class scripts: `PascalCase`  
portraits and sigil image files: `Their Actual Fucking Name Case (sic)`

### Naming Conventions

- Try to keep it 3-4 words at max.
- Be as descriptive as possible.
- Avoid acronyms and abbreviations if at all possible.
- Don't forget to have fun :)

### Block Length

Just... just try to do better in the future. Someone will eventually refactor the city block-sized functions, just try not to create any more.