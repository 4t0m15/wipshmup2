# C# Build Instructions

## Critical: You MUST build the C# project in Godot Editor

The errors you're seeing happen because Godot hasn't compiled the C# scripts yet.

### Steps to Fix:

1. **Close Godot Editor** if it's currently open

2. **Reopen the project** in Godot Editor
   - Open Godot
   - Select the wipshmup2 project
   - Click "Edit"

3. **Build the C# Solution**
   - In Godot Editor, go to: **Project → Tools → C# → Create C# Solution**
   - Then go to: **Build → Build Solution** (or press F6)
   - Wait for the build to complete

4. **Verify the Build**
   - Check the bottom panel for "Build succeeded" message
   - Look for a `bin/` and `obj/` folder in your project directory

5. **Reload Autoloads**
   - Go to: **Project → Project Settings → Autoload tab**
   - Verify all autoloads point to `.cs` files (not `.gd`)
   - Click "Restart" or close and reopen Godot

### Expected Result

After building:
- ✅ EventBus.cs, GameState.cs, EntityFactory.cs, EnemyTemplateManager.cs will load successfully
- ✅ The "does not inherit from Node" errors will disappear
- ✅ You can run the game (though remaining GDScript files will need conversion)

### If Build Fails

If you get build errors:
1. Check the Output panel for specific error messages
2. Make sure .NET 8.0 SDK is installed: `dotnet --version`
3. Try: **Build → Clean Solution**, then **Build → Build Solution** again

### Current Migration Status

**Converted to C# (5 files):**
- ✅ EventBus.cs
- ✅ GameState.cs  
- ✅ EntityFactory.cs
- ✅ EnemyTemplate.cs
- ✅ EnemyTemplateManager.cs

**Still GDScript (~94 files):**
- Remaining autoloads (AudioManager, ConfigManager, etc.)
- All other game systems

### Next Steps

Once the C# project builds successfully, we can either:
- A) Continue converting all remaining files
- B) Test the current partial conversion
- C) Focus on getting core gameplay working first

