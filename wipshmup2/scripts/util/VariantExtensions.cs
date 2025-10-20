using Godot;

namespace wipshmup2.scripts.util
{
    // Helper/extension methods to make working with Godot.Collections and loosely-typed data easier.
    public static class VariantExtensions
    {
        // Dictionary helpers
        public static object GetValueOrDefault(this Godot.Collections.Dictionary dict, object key, object defaultValue)
        {
            if (dict == null)
            {
                return defaultValue;
            }

            if (dict.ContainsKey(key))
            {
                return dict[key];
            }
            return defaultValue;
        }

        // Safe conversions
        public static string AsString(this object v)
        {
            switch (v)
            {
                case null:
                    return string.Empty;
                case string s:
                    return s;
                case StringName sn:
                    return sn.ToString();
                case Node n:
                    return n.ToString();
                default:
                    return v.ToString();
            }
        }

        public static int AsInt32(this object v)
        {
            if (v == null) return 0;
            if (v is int i) return i;
            if (v is long l) return (int)l;
            if (v is float f) return (int)f;
            if (v is double d) return (int)d;
            if (v is bool b) return b ? 1 : 0;
            if (int.TryParse(v.ToString(), out var p)) return p;
            return 0;
        }

        public static uint AsUInt32(this object v)
        {
            var i = AsInt32(v);
            return i < 0 ? 0u : (uint)i;
        }

        public static float AsSingle(this object v)
        {
            if (v == null) return 0f;
            if (v is float f) return f;
            if (v is double d) return (float)d;
            if (v is int i) return i;
            if (v is long l) return l;
            if (float.TryParse(v.ToString(), System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var p)) return p;
            return 0f;
        }

        public static bool AsBool(this object v)
        {
            if (v == null) return false;
            if (v is bool b) return b;
            if (v is int i) return i != 0;
            if (v is long l) return l != 0;
            if (v is float f) return System.Math.Abs(f) > float.Epsilon;
            if (v is double d) return System.Math.Abs(d) > double.Epsilon;
            if (bool.TryParse(v.ToString(), out var p)) return p;
            return false;
        }

        public static Vector2 AsVector2(this object v)
        {
            if (v is Vector2 v2) return v2;
            if (v is Godot.Collections.Array arr && arr.Count >= 2)
            {
                return new Vector2(arr[0].AsSingle(), arr[1].AsSingle());
            }
            return Vector2.Zero;
        }

        public static Color AsColor(this object v)
        {
            if (v is Color c) return c;
            if (v is string s)
            {
                // Try parse HTML color, e.g. "#RRGGBB"
                return Color.FromHtml(s, Colors.White);
            }
            return Colors.White;
        }

        public static Godot.Collections.Dictionary AsGodotDictionary(this object v)
        {
            if (v is Godot.Collections.Dictionary d) return d;
            return new Godot.Collections.Dictionary();
        }

        public static Godot.Collections.Array AsGodotArray(this object v)
        {
            if (v is Godot.Collections.Array a) return a;
            return new Godot.Collections.Array();
        }

        public static Godot.Collections.Array<T> AsGodotArray<T>(this object v)
        {
            if (v is Godot.Collections.Array<T> at) return at;
            var result = new Godot.Collections.Array<T>();
            if (v is Godot.Collections.Array a)
            {
                foreach (var item in a)
                {
                    if (item is T t)
                    {
                        result.Add(t);
                    }
                    else
                    {
                        // Try to convert with ToString for strings
                        if (typeof(T) == typeof(string))
                        {
                            result.Add((T)(object)item.AsString());
                        }
                    }
                }
            }
            return result;
        }
    }
}
