## Setting up different calendar layouts
# It builds a complete calendar layout, whilst using "left_join" with 
# "date" variable
setup_calendar <- function(x, dir = "h", ...) {
  dir <- match.arg(dir, choices = c("h", "v"))
  UseMethod("setup_calendar")
}

setup_calendar.daily <- function(x, dir = "h", ...) {
  # x is a vector of unique dates
  x <- unique(x)
  mday_x <- mday(x)
  month_x <- unique(x - mday_x + 1)
  nfacets <- length(month_x)
  seq_facets <- seq_len(nfacets)
  days_x <- unname(days_in_month(month_x)) # d # unname() get rid of rlang warning
  counter <- map2( # g
    .x = month_x, .y = days_x, ~ .x + 0:(.y - 1)
  )
  # if dir == "h"
  row_idx <- list(rep.int(seq_facets, days_x))
  col_idx <- lapply(days_x, seq_len)
  if (dir == "v") { # reverse col_idx and row_idx when direction is vertical
    col_tmp <- row_idx
    row_idx <- col_idx
    col_idx <- col_tmp
  }
  cal_table <- data.frame(
    ROW = rlang::flatten_int(row_idx),
    COL = rlang::flatten_int(col_idx),
    PANEL = do.call("c", counter)
  )
  return(cal_table)
}

setup_calendar.weekly <- function(x, dir = "h", ...) {
  # x is a vector of unique dates
  x <- unique(x)
  init_counter <- mday(min_na(x))
  wk_x <- isoweek(x)

  # only starts with Monday for ISO week
  col_idx <- wday2(x)
  counter <- init_counter - 1 + x
  # if dir == "h"
  rle_x <- rle(wk_x)
  row_idx <- rep.int(seq_along(rle_x$values), rle_x$lengths)
  if (dir == "v") { # reverse col_idx and row_idx when direction is vertical
    col_tmp <- row_idx
    row_idx <- col_idx
    col_idx <- col_tmp
  }
  cal_table <- data.frame(
    ROW = row_idx,
    COL = col_idx,
    PANEL = counter
  )
  return(cal_table)
}

setup_calendar.monthly <- function(x, dir = "h", sunday = FALSE, 
  nrow = NULL, ncol = NULL, ...) {
  # x is a vector of unique dates
  x <- unique(x)
  month_x <- unique(x - mday(x) + 1)
  nfacets <- length(month_x)
  dims <- wrap_dims(nfacets, nrow = nrow, ncol = ncol)
  nrow <- dims[1]
  ncol <- dims[2]
  days_x <- days_in_month(month_x) # d
  ndays <- 7
  max_wks <- 5
  ncells <- max_wks * ndays
  if (sunday) { # Weekday starts with Sunday
    first_wday <- wday(month_x) # k
  } else { # starts with Monday
    first_wday <- wday2(month_x) # k
  }
  counter_date <- map2(
    .x = month_x, .y = days_x, ~ .x + 0:(.y - 1) 
  )
  counter <- map2( # g
    .x = first_wday, .y = days_x, ~ .x + 0:(.y - 1)
  )
  row_idx <- lapply( # i
    counter, 
    function(x) ifelse(x == ncells, max_wks, ceiling((x %% ncells) / ndays))
  )
  col_idx <- lapply( # j
    counter, 
    function(x) ifelse(x %% ndays == 0, ndays, x %% ndays)
  )
  if (dir == "v") { # reverse col_idx and row_idx when direction is vertical
    col_tmp <- row_idx
    row_idx <- col_idx
    col_idx <- col_tmp
  }

  seq_facets <- seq_len(nfacets)
  m_idx <- ifelse(seq_facets %% ncol == 0, ncol, seq_facets %% ncol)
  last_rep <- m_idx[nfacets]
  n_idx <- rep.int(1:nrow, times = c(rep.int(ncol, nrow - 1), last_rep))
  if (dir == "h") {
    row_idx[] <- map2(
      .x = row_idx, .y = n_idx, ~ .x + max_wks * (.y - 1)
    )
    col_idx[] <- map2(
      .x = col_idx, .y = m_idx, ~ .x + ndays * (.y - 1)
    )
  } else { # dir = "v"
    row_idx[] <- map2(
      .x = row_idx, .y = n_idx, ~ .x + ndays * (.y - 1)
    )
    col_idx[] <- map2(
      .x = col_idx, .y = m_idx, ~ .x + max_wks * (.y - 1)
    )
  }
  cal_table <- data.frame(
    ROW = rlang::flatten_int(row_idx),
    COL = rlang::flatten_int(col_idx),
    MROW = rep.int(n_idx, days_x),
    MCOL = rep.int(m_idx, days_x),
    PANEL = do.call("c", counter_date),
    MPANEL = rep.int(seq_len(nfacets), days_x)
  )
  return(cal_table)
}

