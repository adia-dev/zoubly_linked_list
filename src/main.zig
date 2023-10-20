const std = @import("std");

const Node = struct {
    next: ?*Node = null,
    previous: ?*Node = null,
    content: []u8,

    pub fn print(self: *Node) void {
        std.debug.print(
            \\ Node({*}): {s}
            \\     Previous: {?*} - Next: {?*}
            \\
            \\
        , .{ self, self.content, self.previous, self.next });
    }
};

const DoublyLinkedList = struct {
    const Self = @This();

    len: usize = 0,
    root: ?*Node = null,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        if (self.root == null) {
            return;
        }

        var node = self.root;
        while (node) |n| {
            var next = n.next;
            self._remove(n);
            node = next;
        }

        self.root = null;
        self.len = 0;
    }

    pub fn push(self: *Self, content: []const u8) !void {
        var new_node = try self.allocator.create(Node);

        var dupped_content = try self.allocator.dupe(u8, content);
        new_node.* = .{ .content = dupped_content };
        self.len += 1;

        if (self.root == null) {
            self.root = new_node;
            return;
        }

        var rightmost = self.root;

        while (rightmost) |node| {
            if (node.next == null) {
                break;
            }

            rightmost = node.next;
        }

        new_node.previous = rightmost;
        rightmost.?.next = new_node;
    }

    pub fn remove(self: *Self, content_to_remove: []const u8, only_first_occur: bool) !bool {
        if (self.root == null) {
            return false;
        }

        var node = self.root;
        var removed = false;
        var prev: ?*Node = null;

        while (node) |n| {
            var next = n.next;

            if (std.mem.eql(u8, n.content, content_to_remove)) {
                if (next) |next_n| {
                    next_n.previous = prev;
                }

                if (prev) |prev_n| {
                    prev_n.next = next;
                }

                self._remove(n);
                removed = true;

                if (only_first_occur) {
                    return true;
                }
            } else {
                prev = n;
            }

            node = next;
        }

        return removed;
    }

    pub fn find(self: *Self, content_to_find: []const u8) ?*Node {
        var node = self.root;

        while (node) |n| {
            if (std.mem.eql(u8, n.content, content_to_find)) {
                return n;
            }

            node = n.next;
        }

        return null;
    }

    pub fn for_each(self: *Self, fun: *const fn (*Node) void) void {
        if (self.root == null) {
            return;
        }

        var node = self.root;

        while (node) |n| {
            fun(n);
            node = n.next;
        }
    }

    fn _remove(self: *Self, node_to_remove: *Node) void {
        self.len -= 1;
        self.allocator.free(node_to_remove.content);
        self.allocator.destroy(node_to_remove);
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
}

test "DoublyLinkedList - Test" {
    var ta = std.testing.allocator;

    var dll = DoublyLinkedList.init(ta);
    defer dll.deinit();

    try dll.push("Abdoulaye Dia");
    try dll.push("Itadori Yuji");
    try dll.push("Itadori Yuji");
    try dll.push("Itadori Yuji");
    try dll.push("Itadori Yuji");
    try dll.push("Itadori Yuji");
    try dll.push("Itadori Yuji");
    try dll.push("Itadori Yuji");
    try dll.push("Okkotsu Yuta");
    try dll.push("Sukuna");
    try dll.push("Uruma");
    try dll.push("Gachiakuta");

    const searched_content = "Itadori Yuji";
    std.debug.print("\nLooking for {s}:\n", .{searched_content});
    var found = dll.find(searched_content);

    if (found) |n| {
        std.debug.print("Content found: {*}.\n", .{n});
    } else {
        std.debug.print("Content not found for: {s}.\n", .{searched_content});
    }

    std.debug.print("\n{d} Elements:\n", .{dll.len});
    dll.for_each(Node.print);

    _ = try dll.remove("Itadori Yuji", true);

    std.debug.print("\n{d} Elements:\n", .{dll.len});
    dll.for_each(Node.print);

    _ = try dll.remove("Itadori Yuji", false);
    std.debug.print("\n{d} Elements:\n", .{dll.len});
    dll.for_each(Node.print);
}
