package com.solarpro.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

@Immutable
data class ChartPoint(
    val label: String,
    val receitas: Float,
    val despesas: Float,
)

@Composable
fun FinanceLineChart(
    modifier: Modifier = Modifier,
    points: List<ChartPoint> = sampleFinancePoints(),
    selectedIndex: Int = 6,
    title: String = "Desempenho da semana",
    subtitle: String = "12 - 18 de Maio",
    height: Dp = 360.dp,
) {
    val green = Color(0xFF35B86B)
    val expense = Color(0xFF334155)
    val text = Color(0xFF111827)
    val muted = Color(0xFF64748B)
    val grid = Color(0xFFE8EEF3)

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
    ) {
        Column(
            modifier = Modifier.padding(18.dp),
        ) {
            Text(
                text = title,
                color = text,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = subtitle,
                color = muted,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
            )
            Spacer(modifier = Modifier.height(18.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    LegendItem(color = green, label = "Receitas")
                    LegendItem(color = expense, label = "Despesas")
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "R$ ${points.sumOf { it.receitas.toDouble() }.roundToInt()},00",
                        color = green,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text = "R$ ${points.sumOf { it.despesas.toDouble() }.roundToInt()},00",
                        color = expense,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(height),
            ) {
                FinanceChartCanvas(
                    points = points,
                    selectedIndex = selectedIndex.coerceIn(points.indices),
                    revenueColor = green,
                    expenseColor = expense,
                    gridColor = grid,
                    labelColor = muted,
                    modifier = Modifier.matchParentSize(),
                )

                ChartTooltip(
                    point = points[selectedIndex.coerceIn(points.indices)],
                    revenueColor = green,
                    expenseColor = expense,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(x = (-18).dp, y = 24.dp),
                )
            }
        }
    }
}

@Composable
private fun FinanceChartCanvas(
    points: List<ChartPoint>,
    selectedIndex: Int,
    revenueColor: Color,
    expenseColor: Color,
    gridColor: Color,
    labelColor: Color,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        if (points.size < 2) return@Canvas

        val left = 42.dp.toPx()
        val top = 10.dp.toPx()
        val right = 12.dp.toPx()
        val bottom = 48.dp.toPx()
        val chartWidth = size.width - left - right
        val chartHeight = size.height - top - bottom
        val maxValue = (points.maxOf { maxOf(it.receitas, it.despesas) } * 1.18f)
            .coerceAtLeast(1f)
        val stepX = chartWidth / (points.lastIndex)

        fun y(value: Float): Float = top + chartHeight - (value / maxValue) * chartHeight
        fun x(index: Int): Float = left + stepX * index

        repeat(5) { index ->
            val ratio = index / 4f
            val yy = top + chartHeight * ratio
            drawLine(
                color = gridColor,
                start = Offset(left, yy),
                end = Offset(size.width - right, yy),
                strokeWidth = 1.dp.toPx(),
            )
        }

        val revenueOffsets = points.mapIndexed { index, point ->
            Offset(x(index), y(point.receitas))
        }
        val expenseOffsets = points.mapIndexed { index, point ->
            Offset(x(index), y(point.despesas))
        }

        val revenuePath = smoothPath(revenueOffsets)
        val expensePath = smoothPath(expenseOffsets)

        val fillPath = Path().apply {
            addPath(revenuePath)
            lineTo(revenueOffsets.last().x, top + chartHeight)
            lineTo(revenueOffsets.first().x, top + chartHeight)
            close()
        }

        drawPath(
            path = fillPath,
            brush = Brush.verticalGradient(
                colors = listOf(
                    revenueColor.copy(alpha = 0.18f),
                    revenueColor.copy(alpha = 0.04f),
                    Color.Transparent,
                ),
                startY = top,
                endY = top + chartHeight,
            ),
        )

        drawPath(
            path = revenuePath,
            color = revenueColor,
            style = Stroke(
                width = 4.dp.toPx(),
                cap = StrokeCap.Round,
            ),
        )
        drawPath(
            path = expensePath,
            color = expenseColor,
            style = Stroke(
                width = 3.dp.toPx(),
                cap = StrokeCap.Round,
            ),
        )

        val selectedRevenue = revenueOffsets[selectedIndex]
        val selectedExpense = expenseOffsets[selectedIndex]
        drawLine(
            color = labelColor.copy(alpha = 0.45f),
            start = Offset(selectedRevenue.x, top),
            end = Offset(selectedRevenue.x, top + chartHeight),
            strokeWidth = 1.dp.toPx(),
            pathEffect = PathEffect.dashPathEffect(floatArrayOf(8f, 8f)),
        )

        drawCircle(
            color = Color.White,
            radius = 8.dp.toPx(),
            center = selectedRevenue,
        )
        drawCircle(
            color = revenueColor,
            radius = 6.dp.toPx(),
            center = selectedRevenue,
            style = Stroke(width = 3.dp.toPx()),
        )
        drawCircle(
            color = Color.White,
            radius = 7.dp.toPx(),
            center = selectedExpense,
        )
        drawCircle(
            color = expenseColor,
            radius = 5.dp.toPx(),
            center = selectedExpense,
            style = Stroke(width = 3.dp.toPx()),
        )

        points.forEachIndexed { index, point ->
            drawContext.canvas.nativeCanvas.drawText(
                point.label,
                x(index),
                size.height - 18.dp.toPx(),
                android.graphics.Paint().apply {
                    color = android.graphics.Color.rgb(100, 116, 139)
                    textSize = 11.sp.toPx()
                    textAlign = android.graphics.Paint.Align.CENTER
                    isAntiAlias = true
                },
            )
        }
    }
}

private fun smoothPath(points: List<Offset>): Path {
    return Path().apply {
        moveTo(points.first().x, points.first().y)
        for (index in 0 until points.lastIndex) {
            val current = points[index]
            val next = points[index + 1]
            val controlX = (current.x + next.x) / 2f
            cubicTo(
                controlX,
                current.y,
                controlX,
                next.y,
                next.x,
                next.y,
            )
        }
    }
}

@Composable
private fun LegendItem(color: Color, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(
            modifier = Modifier
                .size(10.dp)
                .clip(CircleShape)
                .background(color),
        )
        Text(
            text = label,
            color = Color(0xFF475569),
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun ChartTooltip(
    point: ChartPoint,
    revenueColor: Color,
    expenseColor: Color,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = point.label.replace("\n", " "),
                color = Color(0xFF111827),
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
            )
            LegendValue(color = revenueColor, text = "Receitas: R$ ${point.receitas.roundToInt()},00")
            LegendValue(color = expenseColor, text = "Despesas: R$ ${point.despesas.roundToInt()},00")
        }
    }
}

@Composable
private fun LegendValue(color: Color, text: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(color),
        )
        Text(
            text = text,
            color = Color(0xFF334155),
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}

private fun sampleFinancePoints() = listOf(
    ChartPoint("12\nSeg", 400f, 140f),
    ChartPoint("13\nTer", 470f, 180f),
    ChartPoint("14\nQua", 600f, 270f),
    ChartPoint("15\nQui", 310f, 130f),
    ChartPoint("16\nSex", 750f, 330f),
    ChartPoint("17\nSáb", 500f, 200f),
    ChartPoint("18\nDom", 800f, 350f),
    ChartPoint("", 430f, 150f),
)

@Preview(showBackground = true, backgroundColor = 0xFFF4F7F5)
@Composable
private fun FinanceLineChartPreview() {
    MaterialTheme {
        Surface(color = Color(0xFFF4F7F5)) {
            FinanceLineChart(
                modifier = Modifier.padding(16.dp),
                points = listOf(
                    ChartPoint("12\nSeg", 400f, 140f),
                    ChartPoint("13\nTer", 470f, 180f),
                    ChartPoint("14\nQua", 600f, 270f),
                    ChartPoint("15\nQui", 310f, 130f),
                    ChartPoint("16\nSex", 750f, 330f),
                    ChartPoint("17\nSáb", 500f, 200f),
                    ChartPoint("18\nDom", 800f, 350f),
                    ChartPoint("", 430f, 150f),
                ),
                selectedIndex = 6,
            )
        }
    }
}
