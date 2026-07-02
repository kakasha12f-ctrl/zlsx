const std = @import("std");
const print = std.debug.print; // print

// конфиг
const Config = struct { allow: bool = true, all: bool = false, reverse: bool = false, flag_l: bool = false, human: bool = false, time: bool = false, sort_size: bool = false, show_size: bool = false, show_time: bool = false, flag_F: bool = false, flag_1: bool = false, flag_m: bool = false };

// структура для хранения файлов
const FileInfo = struct { name: []const u8, kind: std.Io.File.Kind, size: u64, mtime: i128 };

/// main
pub fn main(init: std.process.Init) !void {
    var args = try init.minimal.args.toSlice(init.arena.allocator()); // получаем аргументы (-S, -m и тд)

    const allocator = init.arena.allocator(); // инициализация аллокатора
    var path_list: std.ArrayList([]const u8) = .empty; // создает массив для хранения путей
    defer path_list.deinit(allocator);
    var force_path: bool = false;

    var config = Config{};
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--")) {
            force_path = true;
            continue;
        }

        if (force_path) {
            try path_list.append(allocator, arg);
            continue;
        }

        // инициализация аргументов
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-a")) config.all = true;
            if (std.mem.eql(u8, arg, "-r")) config.reverse = true;
            if (std.mem.eql(u8, arg, "-l")) config.flag_l = true;
            if (std.mem.eql(u8, arg, "-h")) config.human = true;
            if (std.mem.eql(u8, arg, "-t")) config.time = true;
            if (std.mem.eql(u8, arg, "-S")) config.sort_size = true;
            if (std.mem.eql(u8, arg, "-s")) config.show_size = true;
            if (std.mem.eql(u8, arg, "-T")) config.show_time = true;
            if (std.mem.eql(u8, arg, "-F")) config.flag_F = true;
            if (std.mem.eql(u8, arg, "-1")) config.flag_1 = true;
            if (std.mem.eql(u8, arg, "-m")) config.flag_m = true;
            continue;
        }
        try path_list.append(allocator, arg); // добавление путей
    }

    if (path_list.items.len == 0) {
        try path_list.append(allocator, "."); // если путей нет, добавляем базовый (текущая директория)
    }

    for (path_list.items) |p| {
        print("--> Path: {s}\n", .{p});
        runLs(init, config, p) catch |err| {
            if (err == error.FileNotFound) {
                print("zlsx: cannot open access '{s}': No such file or directory\n", .{p});
            } else {
                print("zlsx: unexpected error: '{}' for '{s}'\n", .{ err, p });
            }
        };
    }
}

/// основная функция для zls
pub fn runLs(init: std.process.Init, config: Config, path: []const u8) !void {
    const allocator = init.arena.allocator(); // инициализация аллокатора
    var file_list: std.ArrayList(FileInfo) = .empty; // создаем массив для хранения аргументов
    defer file_list.deinit(allocator);

    var dir = try std.Io.Dir.cwd().openDir(init.io, path, .{ .iterate = true });
    defer dir.close(init.io);

    var iterator = dir.iterateAssumeFirstIteration();
    while (try iterator.next(init.io)) |entry| { // добавление файлов, директорий и тд в массив
        const name_copy = try allocator.dupe(u8, entry.name);

        var file_size: u64 = 0;
        var mtime_ns: i128 = 0;

        const need_stat = config.time or config.sort_size or config.show_size or config.flag_l or config.human or config.show_time;
        if (need_stat) {
            const stat = dir.statFile(init.io, entry.name, .{}) catch {
                file_size = 0;
                mtime_ns = 0;
                continue;
            };

            file_size = stat.size;
            mtime_ns = stat.mtime.nanoseconds;
        }

        try file_list.append(allocator, .{ .name = name_copy, .kind = entry.kind, .size = file_size, .mtime = mtime_ns });
    }
    if (config.time) {
        std.mem.sort(FileInfo, file_list.items, {}, comboratorTime);
    } else if (config.sort_size) {
        std.mem.sort(FileInfo, file_list.items, {}, comporatorSize);
    } else {
        std.mem.sort(FileInfo, file_list.items, {}, comporatorABC); // по умолчанию сортирует вывод по алфавиту
    }

    if (config.reverse) {
        std.mem.reverse(FileInfo, file_list.items);
    }

    for (file_list.items, 0..) |entry, i| { // основной цикл для вывода
        if (!shouldShowFile(entry.name, config)) continue;
        var size_buf: [64]u8 = undefined;

        if (config.flag_l or config.show_size or config.human) {
            const size_str = formate(&size_buf, entry.size, config.human);
            if (config.flag_l or (config.flag_1 and config.show_size)) {
                print("{s:>8} ", .{size_str});
            } else {
                print("{s} ", .{size_str});
            }
        }
        if (config.show_time) {
            print("{d} Sec ", .{@divTrunc(entry.mtime, 1000000000)});
        }
        switch (entry.kind) {
            .directory => print("\x1b[38;2;137;180;250m{s}\x1b[0m", .{printFilesTypes(&size_buf, entry.name, config.flag_F, true, false)}),
            .sym_link => print("\x1b[38;5;116m{s}\x1b[0m", .{printFilesTypes(&size_buf, entry.name, config.flag_F, false, true)}),
            .file => print("{s}", .{entry.name}),
            else => {
                print("{s}", .{entry.name});
            },
        }

        if (config.flag_m) {
            if (i < file_list.items.len - 1) {
                print(", ", .{});
            } else {
                print("  ", .{});
            }
        } else {
            print(" ", .{});
        }

        if (config.flag_l or config.flag_1) {
            print("\n", .{});
        }
    }
    print("\n", .{});
}

/// -a
pub fn shouldShowFile(name: []const u8, config: Config) bool {
    if (config.all) return true;
    return name[0] != '.';
}

/// =F
pub fn printFilesTypes(buf: []u8, name: []const u8, DoOrNot: bool, isDirectory: bool, isSymLink: bool) []const u8 {
    if (DoOrNot) {
        if (isDirectory) {
            return std.fmt.bufPrint(buf, "{s}/", .{name}) catch name;
        } else if (isSymLink) {
            return std.fmt.bufPrint(buf, "{s}@", .{name}) catch name;
        } else {
            return std.fmt.bufPrint(buf, "{s}", .{name}) catch name;
        }
    } else {
        return name;
    }
}

/// -s or -h
pub fn formate(buf: []u8, size: usize, human: bool) []const u8 {
    if (human) {
        if (size < 1024) {
            return std.fmt.bufPrint(buf, "{d}Byte", .{size}) catch "0B";
        } else if (size < 1024 * 1024) {
            const float_size: f64 = @floatFromInt(size);
            return std.fmt.bufPrint(buf, "{d:.1}Kb", .{float_size / 1024.0}) catch "0K";
        } else {
            const float_size: f64 = @floatFromInt(size);
            return std.fmt.bufPrint(buf, "{d:.1}Mb", .{float_size / (1024 * 1024)}) catch "0M";
        }
    } else {
        return std.fmt.bufPrint(buf, "{d}", .{size}) catch "0";
    }
}

/// сортирование по времени
pub fn comboratorTime(context: void, lhs: FileInfo, rhs: FileInfo) bool {
    _ = context;

    return lhs.mtime > rhs.mtime;
}

/// сортирование по размерам
pub fn comporatorSize(context: void, lhs: FileInfo, rhs: FileInfo) bool {
    _ = context;

    return lhs.size > rhs.size;
}

/// сортирование по алфавиту
pub fn comporatorABC(context: void, lhs: FileInfo, rhs: FileInfo) bool {
    _ = context;
    return std.mem.lessThan(u8, lhs.name, rhs.name);
}
