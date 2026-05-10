// DynamicLayout Jetpack Compose renderer — renders PFDL JSON in Android Compose apps.
// Single-file. Works on Compose BOM 2024+.
//
// Example:
//   DynamicLayout(
//       spec = mapOf("title" to "My Page", "layout" to listOf(mapOf("type" to "LABEL", "key" to "l", "label" to "Hello"))),
//       remember { mutableStateMapOf() }
//   )

package dynamiclayout

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.font.FontWeight

@Composable
fun DynamicLayout(
    spec: Map<String, Any?>?,
    data: MutableMap<String, Any?> = mutableStateMapOf(),
    onAction: ((String, Map<String, Any?>?) -> Unit)? = null
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        spec?.get("title")?.let {
            Text(it.toString(), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(16.dp))
        }

        (spec?.get("layout") as? List<*>)?.forEach { el ->
            ElementView((el as? Map<String, Any?>) ?: emptyMap(), data, onAction)
        }

        val actions = spec?.get("actions") as? List<*>
        if (!actions.isNullOrEmpty()) {
            HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                actions.forEach { el ->
                    ElementView((el as? Map<String, Any?>) ?: emptyMap(), data, onAction)
                }
            }
        }
    }
}

@Composable
fun ElementView(el: Map<String, Any?>, data: MutableMap<String, Any?>, onAction: ((String, Map<String, Any?>?) -> Unit)?) {
    when (el["type"]) {
        "ROW" -> Row {
            (el["content"] as? List<*>)?.forEach { ElementView(it as Map<String, Any?>, data, onAction) }
        }
        "COL" -> Column {
            (el["content"] as? List<*>)?.forEach { ElementView(it as Map<String, Any?>, data, onAction) }
        }
        "FIELDSET" -> Card(modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)) {
            Column(modifier = Modifier.padding(12.dp)) {
                el["title"]?.let { Text(it.toString(), fontWeight = FontWeight.SemiBold) }
                (el["content"] as? List<*>)?.forEach { ElementView(it as Map<String, Any?>, data, onAction) }
            }
        }
        "GROUP" -> Column(modifier = Modifier.padding(bottom = 8.dp)) {
            (el["content"] as? List<*>)?.forEach { ElementView(it as Map<String, Any?>, data, onAction) }
        }
        "LABEL" -> Text(el["label"]?.toString() ?: "", fontWeight = FontWeight.Medium, modifier = Modifier.padding(bottom = 4.dp))
        "ALERT" -> {
            val bg = mapOf("info" to Color(0xFFE0F0FF), "warning" to Color(0xFFFFF3CD), "danger" to Color(0xFFFFE0E0), "success" to Color(0xFFD4EDDA))
            Card(colors = CardDefaults.cardColors(containerColor = bg[el["color"]?.toString()] ?: Color(0xFFE0F0FF))) {
                Text(el["message"]?.toString() ?: "", modifier = Modifier.padding(12.dp))
            }
        }
        "BADGE" -> {
            val colors = mapOf("primary" to Color(0xFF0D6EFD), "secondary" to Color(0xFF6C757D), "success" to Color(0xFF198754))
            Surface(color = colors[el["color"]?.toString()] ?: Color.Gray, shape = MaterialTheme.shapes.small) {
                Text(el["title"]?.toString() ?: "", color = Color.White, style = MaterialTheme.typography.labelSmall, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp))
            }
        }
        "SPACER" -> Spacer(Modifier.height(((el["width"] as? Number)?.toFloat() ?: 20f).dp))
        "PROGRESS" -> Column {
            el["label"]?.let { Text(it.toString()) }
            LinearProgressIndicator(progress = { ((el["progress"] as? Number)?.toFloat() ?: 0f) / 100f }, modifier = Modifier.fillMaxWidth())
        }
        "INPUT" -> {
            val id = el["id"]?.toString() ?: ""
            val dt = el["dataType"]?.toString() ?: "STRING"
            val value = data[id]?.toString() ?: ""
            var text by remember(id, value) { mutableStateOf(value) }
            OutlinedTextField(
                value = text, onValueChange = { text = it; data[id] = it },
                label = { Text(el["label"]?.toString() ?: "") },
                modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
            )
        }
        "CHECKBOX" -> {
            val id = el["id"]?.toString() ?: ""
            var checked by remember { mutableStateOf(data[id] == true) }
            Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                Checkbox(checked = checked, onCheckedChange = { checked = it; data[id] = it })
                Text(el["label"]?.toString() ?: "")
            }
        }
        "TEXTAREA" -> {
            val id = el["id"]?.toString() ?: ""
            var text by remember { mutableStateOf(data[id]?.toString() ?: "") }
            OutlinedTextField(
                value = text, onValueChange = { text = it; data[id] = it },
                label = { Text(el["label"]?.toString() ?: "") },
                minLines = (el["rows"] as? Number)?.toInt() ?: 3,
                modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
            )
        }
        "SELECT" -> {
            val id = el["id"]?.toString() ?: ""
            val values = (el["values"] as? List<*>)?.map {
                val m = it as Map<*, *>
                m["id"].toString() to m["displayName"].toString()
            } ?: emptyList()
            var selected by remember { mutableStateOf(data[id]?.toString() ?: "") }
            var expanded by remember { mutableStateOf(false) }
            Box {
                OutlinedTextField(
                    value = values.firstOrNull { it.first == selected }?.second ?: "",
                    onValueChange = {}, readOnly = true,
                    label = { Text(el["label"]?.toString() ?: "") },
                    modifier = Modifier.fillMaxWidth()
                )
                DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                    values.forEach { (vId, name) ->
                        DropdownMenuItem(text = { Text(name) }, onClick = { selected = vId; data[id] = vId; expanded = false })
                    }
                }
            }
        }
        "RATING" -> {
            val id = el["id"]?.toString() ?: ""
            var rating by remember { mutableIntStateOf((data[id] as? Number)?.toInt() ?: 0) }
            Row {
                el["label"]?.let { Text(it.toString()) }
                (1..5).forEach { n ->
                    Text(if (n <= rating) "★" else "☆", color = Color(0xFFFFC107),
                        modifier = Modifier.padding(4.dp).clickable { rating = n; data[id] = n })
                }
            }
        }
        "READONLY_FIELD" -> Column {
            el["label"]?.let { Text(it.toString(), fontWeight = FontWeight.Medium) }
            Text(data[el["id"]?.toString()]?.toString() ?: "—", modifier = Modifier.padding(8.dp).fillMaxWidth().background(Color(0xFFF8F9FA), MaterialTheme.shapes.small))
        }
        "BUTTON" -> {
            val colors = mapOf("primary" to MaterialTheme.colorScheme.primary, "secondary" to Color.Gray, "danger" to Color.Red)
            Button(onClick = { onAction?.invoke(el["id"]?.toString() ?: "", el["responseAction"] as? Map<String, Any?>) },
                colors = ButtonDefaults.buttonColors(containerColor = colors[el["color"]?.toString()] ?: MaterialTheme.colorScheme.primary)) {
                Text(el["title"]?.toString() ?: el["id"]?.toString() ?: "")
            }
        }
        else -> Text("Unknown: ${el["type"]}", color = Color.Red)
    }
}

private fun Modifier.clickable(onClick: () -> Unit): Modifier = this.then(
    Modifier.clickable(onClick = onClick)
)
