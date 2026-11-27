package com.example.helloworld.ui

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.max

class DraggableMenuGrid(context: Context) : FrameLayout(context) {
    private val store = MenuLayoutStore(context)
    private val handleSize = dp(20)
    private var mode = MODE_NONE
    private var startX = 0f
    private var startY = 0f
    private var startLeft = 0
    private var startTop = 0
    private var startWidth = 0
    private var startHeight = 0

    init {
        isClickable = true
        addView(buildGrid(), LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        addView(
            View(context).apply {
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#8FA394"))
                    cornerRadius = (handleSize / 5).toFloat()
                }
            },
            LayoutParams(handleSize, handleSize).apply {
                gravity = Gravity.BOTTOM or Gravity.END
                rightMargin = dp(2)
                bottomMargin = dp(2)
            }
        )
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        post {
            val params = layoutParams as? LayoutParams ?: return@post
            val saved = store.bounds
            val width = saved?.width ?: dp(300)
            val height = saved?.height ?: dp(300)
            val parentWidth = (parent as? View)?.width ?: width
            params.width = width
            params.height = height
            params.gravity = Gravity.TOP or Gravity.START
            params.leftMargin = saved?.left ?: max(0, (parentWidth - width) / 2)
            params.topMargin = saved?.top ?: dp(100)
            setLayoutParams(params)
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                startX = event.x
                startY = event.y
                val params = layoutParams as? LayoutParams ?: return false
                startLeft = params.leftMargin
                startTop = params.topMargin
                startWidth = params.width
                startHeight = params.height
                mode = if (event.x >= width - handleSize && event.y >= height - handleSize) {
                    MODE_RESIZE
                } else {
                    MODE_DRAG
                }
                parent?.requestDisallowInterceptTouchEvent(true)
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                val params = layoutParams as? LayoutParams ?: return false
                val dx = (event.x - startX).toInt()
                val dy = (event.y - startY).toInt()
                if (mode == MODE_RESIZE) {
                    params.width = max(dp(160), startWidth + dx)
                    params.height = max(dp(160), startHeight + dy)
                } else if (mode == MODE_DRAG) {
                    params.leftMargin = max(0, startLeft + dx)
                    params.topMargin = max(0, startTop + dy)
                }
                setLayoutParams(params)
                return true
            }

            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                val params = layoutParams as? LayoutParams
                if (params != null && mode != MODE_NONE) {
                    store.bounds = MenuLayoutStore.Bounds(
                        params.leftMargin,
                        params.topMargin,
                        params.width,
                        params.height
                    )
                }
                mode = MODE_NONE
                parent?.requestDisallowInterceptTouchEvent(false)
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    private fun buildGrid(): View {
        val grid = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#FFFDF5"))
        }
        for (row in 0 until ROW_COUNT) {
            val rowView = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f)
            }
            for (column in 0 until COLUMN_COUNT) {
                val index = row * COLUMN_COUNT + column
                val cell = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER_HORIZONTAL
                    layoutParams = LinearLayout.LayoutParams(0, LayoutParams.MATCH_PARENT, 1f)
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#FFFDF5"))
                        setStroke(dp(1), Color.parseColor("#A9B9AC"))
                    }
                    setPadding(dp(3), dp(8), dp(3), dp(3))
                }
                cell.addView(
                    ImageView(context).apply {
                        setImageResource(ICONS[index])
                        scaleType = ImageView.ScaleType.FIT_CENTER
                        layoutParams = LinearLayout.LayoutParams(dp(24), dp(24))
                    }
                )
                cell.addView(
                    TextView(context).apply {
                        text = LABELS[index]
                        textSize = 10f
                        setTextColor(Color.parseColor("#2F3A32"))
                        gravity = Gravity.CENTER
                        layoutParams = LinearLayout.LayoutParams(
                            LayoutParams.MATCH_PARENT,
                            LayoutParams.WRAP_CONTENT
                        ).apply { topMargin = dp(4) }
                    }
                )
                rowView.addView(cell)
            }
            grid.addView(rowView)
        }
        return grid
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    private companion object {
        const val MODE_NONE = 0
        const val MODE_DRAG = 1
        const val MODE_RESIZE = 2
        const val ROW_COUNT = 3
        const val COLUMN_COUNT = 3
        val LABELS = arrayOf(
            "View", "Manage", "Search",
            "Add", "Edit", "Delete",
            "Share", "Send", "Agenda"
        )
        val ICONS = intArrayOf(
            android.R.drawable.ic_menu_view,
            android.R.drawable.ic_menu_manage,
            android.R.drawable.ic_menu_search,
            android.R.drawable.ic_menu_add,
            android.R.drawable.ic_menu_edit,
            android.R.drawable.ic_menu_delete,
            android.R.drawable.ic_menu_share,
            android.R.drawable.ic_menu_send,
            android.R.drawable.ic_menu_agenda
        )
    }
}
