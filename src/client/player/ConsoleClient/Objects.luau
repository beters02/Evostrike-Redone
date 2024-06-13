local Objects = {}

function Objects.newTextLine(console, msg, color)
    local item: TextLabel = console.gui.MainFrame.ReturnTextFrame.Item:Clone()
    item.Parent = console.gui.MainFrame.ReturnTextFrame
    item.Text = msg
    item.Name = "Item" .. tostring(console.lineIndex)

    if console.cfg.print_line_index then
        item.Text = tostring(console.lineIndex) .. ": " .. msg
    end

    item.TextColor3 = color
    item.Visible = true
    return item
end

return Objects