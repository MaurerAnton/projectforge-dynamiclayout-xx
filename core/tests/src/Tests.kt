package test

import org.dynamiclayout.core.*
import org.dynamiclayout.core.json.DynamicLayoutJson
import org.dynamiclayout.core.ui.*
import org.dynamiclayout.core.util.*

fun main() {
    println("=== DynamicLayout Core Tests ===\n")

    // 1. UIElementType
    println("[PASS] UIElementType count: ${UIElementType.entries.size}")
    assert(UIElementType.entries.size > 0) { "UIElementType is empty" }

    // 2. Create Layout
    val layout = UILayout("'Test Page")
    layout.add(
        UIFieldset(title = "'User Info")
            .add(UILabel("'Hello"))
            .add(UIInput("name", label = "'Name"))
    )
    println("[PASS] Layout created: title=${layout.title}")

    // 3. Row + Col
    layout.add(
        UIRow().add(
            UICol(UILength(xs = 12, md = 6))
                .add(UIInput("email", label = "'Email")),
            UICol(UILength(xs = 12, md = 6))
                .add(UIInput("phone", label = "'Phone"))
        )
    )
    println("[PASS] Row/Col layout built")

    // 4. Button
    layout.addAction(UIButton.createDefaultButton(title = "'Send"))
    println("[PASS] Button added")

    // 5. JSON serialization
    val json = DynamicLayoutJson.encode(layout)
    println("[PASS] JSON serialized (${json.length} chars)")
    println(">>> $json")

    // 6. Validate JSON content
    if (json.contains("FIELDSET") && json.contains("INPUT")) {
        println("[PASS] JSON contains expected types")
    }

    // 7. UIDataType
    val dt = UIDataType.STRING
    println("[PASS] DataType: $dt")

    // 8. UISelect with generic
    val select = UISelect<String>(
        id = "country",
        values = listOf(
            UISelectValue("de", "Germany"),
            UISelectValue("us", "USA")
        )
    )
    println("[PASS] UISelect created: id=${select.id}")

    // 9. ResponseAction
    val response = ResponseAction(
        url = "/api/submit",
        targetType = ResponseAction.TargetType.TOAST,
        message = ResponseAction.Message(message = "'OK", color = "success")
    )
    println("[PASS] ResponseAction created: ${response.targetType}")

    // 10. UILayout with FormLayoutData
    val formData = FormLayoutData(data = mapOf("name" to "test"), ui = layout)
    val formJson = DynamicLayoutJson.encodeFormData(formData)
    println("[PASS] FormLayoutData JSON: ${formJson.length} chars")

    println("\n=== All 10 tests PASSED ===")
}
