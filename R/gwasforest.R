#' Make forest plot with GWAS data
#'
#' Extract and reform data from GWAS results, and then make a single integrated forest plot containing multiple windows of which each shows the result of individual SNPs (or other items of interest).
#'
#' @param customFilename,customFilename_results string, relative or full path to the input file. customFilename for raw GWAS data file, and customFilename_results for gwasforest-generated results file. If customFilename_results is provided, certain downstream calculations will be skipped.
#' @param customFilename_studyName (optional) string, relative or full path to the study name file, required if users want to use their own study names which is not standardized (see "stdColnames"); all study names should be in one column with a header; also, study names should be in the order of that they first appear in the input data columns.
#' @param keepStudyOrder logical, whether to keep studies (except for meta study) in the original order provided by user (from customFilename_studyName), or sort them alphabetically on the combined forest plot; meta study will always be put at the bottom of the combined forest plot.
#' @param stdColnames logical, whether the input data has standardized column names as provided in the instruction example, if TRUE, column order doesn't matter (except that study1 needs to be the Meta study); if FALSE, see "customColnames".
#' @param customColnames character, case-sensitive, can be a vector, choose from c("Value", "StdErr") or c("Value", "Upper", "Lower") based on what columns are contained in the input data; required if stdColnames = FALSE, also the input data need to be grouped by study while in the customColnames order, e.g. Study1__Value, Study1__StdErr, Study2__Value, Study2__StdErr...; in addition, each study should contain the same number of columns.
#' @param calculateEXP logical, whether to calculate exp(Value), if TRUE, downstream calculateCI will also take exp into consideration.
#' @param calculateCI logical, whether to calculate Confidence Interval, if TRUE, input data need to contain "StdErr" column; if FALSE, input data need to contain "Upper" and "Lower" columns.
#' @param valueFormat character, format of Value column, e.g. "Effect", "Beta", "OR", "HR", "logRR"...
#' @param metaStudy character, which study is the meta study, by default "Study1" (the first study appear in the input data columns).
#' @param colorMode character, choose from c("mono", "duo", "diverse"), mono - render all studies including meta study in the same color, duo - highlight meta study, diverse - render all studies in different colors.
#' @param forestLayout character, or integer vector, determines the layout of the combined forest plot, by default use "auto" which will automatically arrange the combined forest plot; or user can explicitly set the row/column layout by providing a vector c(rowNum, colNum).
#' @param plotTitle character/string, the title of the combined forest plot, can be customized or simply set to "auto".
#' @param showMetaValue logical, whether to show value for meta group on the combined forest plot.
#' @param outputFolderPath string, relative or full path to the output folder, can be set to NULL (no output file will be written to the file system).
#'
#' @return list, users can run the function without assigning the return value to a variable. If assigned to a variable, it will be a list containing GWAS results (dataframe) and GWAS forest plot (ggplot2 object).
#'
#' @examples
#' # customFilename in dataframe format (with standardized column names)
#' tempValue = runif(n = 18, min = 0.01, max = 2)
#' tempStdErr = tempValue / rep(3:5, times = 6)
#' eg_customFilename = data.frame(paste0("Marker", 1:6), tempValue[1:6],
#'     tempStdErr[1:6], tempValue[7:12], tempStdErr[7:12], tempValue[13:18],
#'     tempStdErr[13:18], stringsAsFactors = FALSE)
#' colnames(eg_customFilename) = c("MarkerName", paste0(rep("Study", times = 6),
#'     rep(1:3, each = 2), sample(LETTERS, 6)))
#' rm(tempValue, tempStdErr)
#' eg_customFilename_studyName = data.frame("studyName" = paste0("Study", 1:3),
#'     stringsAsFactors = FALSE)
#' eg_returnList = gwasforest(eg_customFilename, customFilename_studyName =
#'     eg_customFilename_studyName, stdColnames = FALSE, customColnames = c("Value",
#'     "StdErr"), valueFormat = "Effect", metaStudy = "Study1", colorMode = "duo")
#'
#' # customFilename in dataframe format (without standardized column names),
#' # with customFilename_studyName provided in dataframe format
#' tempValue = runif(n = 18, min = 0.01, max = 2)
#' tempStdErr = tempValue / rep(3:5, times = 6)
#' eg_customFilename = data.frame(paste0("Marker", 1:6), tempValue[1:6],
#'     tempStdErr[1:6], tempValue[7:12], tempStdErr[7:12], tempValue[13:18],
#'     tempStdErr[13:18], stringsAsFactors = FALSE)
#' colnames(eg_customFilename) = c("MarkerName", paste0(rep("Study", times = 6),
#'     rep(1:3, each = 2), sample(LETTERS, 6)))
#' rm(tempValue, tempStdErr)
#' eg_customFilename_studyName = data.frame("studyName" = paste0("Study", 1:3),
#'     stringsAsFactors = FALSE)
#' eg_returnList = gwasforest(eg_customFilename, customFilename_studyName =
#'     eg_customFilename_studyName, stdColnames = FALSE, customColnames = c("Value",
#'     "StdErr"), valueFormat = "Effect", metaStudy = "Study1", colorMode = "duo")
#'
#' # customFilename_results in dataframe format (run either of the two examples
#' # above to see the example results)
#' eg_customFilename_results = eg_returnList[[1]]
#'
#' @export

# create gwasforest function
gwasforest = function(customFilename, customFilename_results = NULL, customFilename_studyName = NULL, keepStudyOrder = TRUE, stdColnames = FALSE, customColnames = NULL, calculateEXP = FALSE, calculateCI = TRUE, valueFormat = "Effect", metaStudy = "Study1", colorMode = "mono", forestLayout = "auto", plotTitle = "auto", showMetaValue = TRUE, outputFolderPath = NULL) {

  # preset valueFormat_show for plot title and ylab
  if (calculateEXP == TRUE) {
    valueFormat_show = paste0("exp(", valueFormat, ")")
  } else {
    valueFormat_show = valueFormat
  }

  # load GWAS data (from external file or internal variable)
  if (is.character(customFilename)) {
    gwas_data = data.table::fread(file = customFilename, stringsAsFactors = FALSE, na.strings = c("NULL", "NA", ""), header = TRUE)
    gwas_data = data.frame(gwas_data, stringsAsFactors = FALSE)
  } else if (is.data.frame(customFilename)) {
    gwas_data = customFilename
  } else {
    print("customFilename is not provided, or is in the wrong format, please double-check and rerun the function")
    stop()
  }

  # check gwas_data columns
  if (stdColnames == TRUE) {
    print("Column names are in the same format as instruction example")
  } else if (stdColnames == FALSE & !is.null(customColnames)) {
    print(paste0("Column names are grouped by study and in the order of |", paste0(customColnames, collapse = ", "), "|"))
    print("Start reforming")
  } else {
    print("Column names are NOT in the same format as instruction example, custom colnames required")
    stop()
  }

  # extract/set/load gwas_studyName, overwrite metaStudy
  if (stdColnames == TRUE) {
    gwas_studyName = unique(gsub("(^.+)__.+$", "\\1", colnames(gwas_data)[-1])) # extract
  } else if (stdColnames == FALSE & is.null(customFilename_studyName)) {
    gwas_studyName = paste0("Study", seq(1, (ncol(gwas_data) - 1) / length(customColnames), by = 1)) # set
    metaStudy = "Study1"
  } else if (stdColnames == FALSE & is.character(customFilename_studyName)) {
    gwas_studyName = data.table::fread(file = customFilename_studyName, stringsAsFactors = FALSE, header = TRUE) # load
    gwas_studyName = unique(unlist(gwas_studyName))
  } else if (stdColnames == FALSE & is.data.frame(customFilename_studyName)) {
    gwas_studyName = unique(unlist(customFilename_studyName))
  }

  # reset colnames(gwas_data)
  if (stdColnames == FALSE & !is.null(customColnames)) {
    tempColnames = paste0(rep(gwas_studyName, each = length(customColnames)), "__", customColnames)
    colnames(gwas_data) = c("MarkerName", tempColnames)
    rm(tempColnames)
  } else if (stdColnames == TRUE) {
    colnames(gwas_data)[1] = "MarkerName"
  }

  # extract markerName
  gwas_markerName = gwas_data$MarkerName

  # reorder gwas_data and gwas_studyName, make sure they are in the same order and MarkerName always at the first column
  gwas_data = data.frame("MarkerName" = gwas_data$MarkerName, subset(gwas_data[, -1], select = sort(colnames(gwas_data)[-1])), stringsAsFactors = FALSE)
  if (keepStudyOrder == TRUE & !is.null(customFilename_studyName)) {
    gwas_studyName_original = gwas_studyName
  }
  gwas_studyName = sort(gwas_studyName)

  # generate or load GWAS results
  if (is.null(customFilename_results)) {

    # calculate exponential of Value (exp(Value))
    if (calculateEXP == TRUE & ("Value" %in% customColnames | stdColnames == TRUE)) {
      print("Start calculating exp(Value)")
      gwas_effect = subset(gwas_data, select = grepl("__Value$", colnames(gwas_data)))
      gwas_effect = subset(gwas_effect, select = sort(colnames(gwas_effect)))
      colnames(gwas_effect) = gwas_studyName
      gwas_or = apply(gwas_effect, MARGIN = 1, FUN = function(x) {
        if (is.na(x[metaStudy])) {
          x = rep(NA, times = length(gwas_studyName))
        } else if (x[metaStudy] > 0) {
          x = exp(x)
        } else {
          x = exp(-x)
        }
        return(x)
      })
      gwas_or = t(gwas_or)
      rm(gwas_effect)
    } else if (calculateEXP == FALSE & ("Value" %in% customColnames | stdColnames == TRUE)) {
      print("Loading user-provided values")
      gwas_or = subset(gwas_data, select = grepl("__Value$", colnames(gwas_data)))
      gwas_or = subset(gwas_or, select = sort(colnames(gwas_or)))
    } else {
      print("User chose not to calculate exp(Value), but no value or exp(Value) is found, please check")
      stop()
    }
    colnames(gwas_or) = gwas_studyName
    rownames(gwas_or) = gwas_markerName

    # calculate Confidence Interval (CI)
    if (calculateCI == TRUE & ("StdErr" %in% customColnames | stdColnames == TRUE)) {
      gwas_stderr = as.matrix(subset(gwas_data, select = grepl("__StdErr$", colnames(gwas_data))))
      gwas_stderr = subset(gwas_stderr, select = sort(colnames(gwas_stderr)))
      colnames(gwas_stderr) = gwas_studyName
      if (calculateEXP == TRUE) {
        print("Start calculating Confidence Interval (exponential)")
        gwas_upper = gwas_or * exp(gwas_stderr * 1.96)
        gwas_lower = gwas_or / exp(gwas_stderr * 1.96)
      } else {
        print("Start calculating Confidence Interval (non-exponential)")
        gwas_upper = gwas_or + gwas_stderr * 1.96
        gwas_lower = gwas_or - gwas_stderr * 1.96
      }
      rm(gwas_stderr)
    } else if (calculateCI == FALSE & (("Upper" %in% customColnames & "Lower" %in% customColnames) | stdColnames == TRUE)) {
      print("Loading user-provided Upper and Lower range for Confidence Interval")
      gwas_upper = subset(gwas_data, select = grepl("__Upper$", colnames(gwas_data)))
      gwas_upper = subset(gwas_upper, select = sort(colnames(gwas_upper)))
      colnames(gwas_upper) = gwas_studyName
      gwas_lower = subset(gwas_data, select = grepl("__Lower$", colnames(gwas_data)))
      gwas_lower = subset(gwas_lower, select = sort(colnames(gwas_lower)))
      colnames(gwas_lower) = gwas_studyName
      if (calculateEXP == TRUE) {
        gwas_upper = exp(gwas_upper)
        gwas_lower = exp(gwas_lower)
      }
    } else {
      print("User chose not to calculate CI, but no CI is found, please check")
      stop()
    }
    rownames(gwas_upper) = gwas_markerName
    rownames(gwas_lower) = gwas_markerName

    # combine Value/exp(Value), Upper and Lower into results
    gwas_results = list()
    for (i in 1:length(gwas_studyName)) {
      gwas_results[[i]] = data.frame("MarkerName" = gwas_markerName, "Value" = gwas_or[, i], "Upper" = gwas_upper[, i], "Lower" = gwas_lower[, i], "StudyName" = rep(gwas_studyName[i], times = length(gwas_markerName)), stringsAsFactors = FALSE)
    }
    rm(i)
    gwas_results = dplyr::bind_rows(gwas_results)
    gwas_results["CI"] = ifelse(gwas_results$StudyName == metaStudy, paste0(round(gwas_results$Value, 2), "(", round(gwas_results$Lower, 2), "-", round(gwas_results$Upper, 2), ")" ), NA)
    gwas_results["Value"] = round(gwas_results$Value, 2)
    rm(gwas_or, gwas_upper, gwas_lower)

    # output gwas results to csv file
    tempCSV = gwas_results
    tempCSV["CI"] = paste0(round(tempCSV$Value, 2), "(", round(tempCSV$Lower, 2), "-", round(tempCSV$Upper, 2), ")" )
    gwas_results_fullCI = tempCSV
    if (!is.null(outputFolderPath)) {
      if (is.character(customFilename)) {
        customFilename_noPath = gsub("^.*/(.+\\..+)$", "\\1", customFilename)
      } else {
        customFilename_noPath = "gwasforest_generated"
      }
      print(glue::glue("Based on user's choice, GWAS results output file will be generated in {outputFolderPath}"))
      utils::write.csv(tempCSV, file = paste0(outputFolderPath, customFilename_noPath, "_results.csv"), quote = FALSE, row.names = FALSE)
      rm(customFilename_noPath)
    } else {
      print("Based on user's choice, GWAS results output file will not be generated")
    }
    rm(tempCSV)
  } else {
    print("GWAS results detected, skip unnecessary calculations; please make sure the results are generated by gwasforest function, or have the same format and column names as instruction example")
    if (is.character(customFilename_results)) {
      gwas_results = utils::read.csv(file = customFilename_results, stringsAsFactors = FALSE)
    } else if (is.data.frame(customFilename_results)) {
      gwas_results = customFilename_results
    }
    gwas_results_fullCI = gwas_results
    gwas_results["CI"] = ifelse(gwas_results$StudyName == metaStudy, paste0(round(gwas_results$Value, 2), "(", round(gwas_results$Lower, 2), "-", round(gwas_results$Upper, 2), ")" ), NA)
    gwas_results["Value"] = round(gwas_results$Value, 2)
  }

  # turn on/off showing CI values on the forest plot
  if (showMetaValue == FALSE) {
    gwas_results["CI"] = NA
  }

  # set layout for the combined gwas forest plot
  if ("auto" %in% forestLayout) {
    forestLayout_row_temp = c(length(gwas_markerName) %% c(5, 4, 3), (length(gwas_markerName) + 1) %% c(5, 4, 3), (length(gwas_markerName) + 2) %% c(5, 4, 3))
    names(forestLayout_row_temp) = c(length(gwas_markerName) %/% c(5, 4, 3), (length(gwas_markerName) + 1) %/% c(5, 4, 3), (length(gwas_markerName) + 2) %/% c(5, 4, 3))
    forestLayout_row = grep("^0$", forestLayout_row_temp)[1]
    forestLayout_row = as.numeric(names(forestLayout_row_temp)[forestLayout_row])
    forestLayout_col = ceiling(length(gwas_markerName) / forestLayout_row)
    rm(forestLayout_row_temp)
  } else {
    forestLayout_row = forestLayout[1]
    forestLayout_col = forestLayout[2]
    tempLayout = forestLayout_row * forestLayout_col
    if (tempLayout < length(gwas_markerName)) {
      print("The size of the combined forest plot is beyond the user-provided layout, please double-check and reset the layout")
      rm(tempLayout, forestLayout_row, forestLayout_col)
      stop()
    }
    rm(tempLayout)
  }

  # adjust width and height of the combined gwas forest plot
  gwas_width = forestLayout_col * 4
  gwas_height = forestLayout_row * 3

  # reset title for the combined gwas forest plot
  if (plotTitle == "auto") {
    plotTitle = glue::glue("Fig 1. {valueFormat_show} of {length(gwas_markerName)} selected items by {length(gwas_studyName)} groups")
  }

  # reform gwas_results.p and set color scheme for point and error bar
  gwas_results.p = gwas_results
  if (keepStudyOrder == TRUE & !is.null(customFilename_studyName)) {
    print("As per user's request, all studies except meta study will be set in the original order from top to bottom on the forest plot")
    gwas_results.p["StudyName"] = factor(gwas_results.p$StudyName, levels = c(metaStudy, rev(setdiff(gwas_studyName_original, metaStudy)))) # studies in original order, make metaStudy always appear at the bottom of the forest plot
  } else {
    print("All studies except meta study will be set in alphabetical order from top to bottom on the forest plot")
    gwas_results.p["StudyName"] = factor(gwas_results.p$StudyName, levels = c(metaStudy, rev(setdiff(gwas_studyName, metaStudy)))) # studies in alphabetical order, make metaStudy always appear at the bottom of the forest plot
  }
  if (colorMode == "mono") {
    gwas_results.p["ColorGroup"] = "mono"
    gwas_colorScheme = c(rep("black", times = length(gwas_studyName)))
  } else if (colorMode == "duo") {
    gwas_results.p["ColorGroup"] = ifelse(gwas_results.p$StudyName == metaStudy, "meta", "others")
    gwas_colorScheme = c("red3", rep("black", times = length(gwas_studyName) - 1))
  } else if (colorMode == "diverse") {
    gwas_results.p["ColorGroup"] = gwas_results.p$StudyName
    gwas_colorScheme = colorspace::heat_hcl(n = (length(gwas_studyName) + 1), h = c(0, 360), l = c(90, 45), c = c(45, 90), power = 1)[-1]
    gwas_colorScheme = rev(gwas_colorScheme)
  }

  # render gwas forest plot
  gwas_forest = suppressWarnings(
    ggplot2::ggplot(gwas_results.p, ggplot2::aes(x = StudyName, y = Value, ymin = Lower, ymax = Upper))
    + ggplot2::facet_wrap(~MarkerName, nrow = forestLayout_row, ncol = forestLayout_col, scales = "free", strip.position = "top")
    + ggplot2::geom_pointrange(ggplot2::aes(shape = StudyName, col = ColorGroup), cex = 0.5)
    + ggplot2::coord_flip()
    + ggplot2::scale_shape_manual(values = c(4, rep(20, times = length(gwas_studyName) - 1)))
    + ggplot2::scale_color_manual(values = gwas_colorScheme)
    + ggplot2::geom_hline(ggplot2::aes(fill = StudyName), yintercept = 1, linetype = 2)
    + ggplot2::geom_errorbar(ggplot2::aes(ymin = Lower, ymax = Upper, col = ColorGroup), width = 0.2, cex = 1)
    + ggrepel::geom_text_repel(ggplot2::aes(label = CI), direction = "y", nudge_x = 0.05)
    + ggplot2::ylab(glue::glue("{valueFormat_show} with 95% Confidence Interval"))
    + ggplot2::xlab("Group")
    + ggplot2::theme_classic()
    + ggplot2::theme(panel.grid.major.y = ggplot2::element_line(colour = "grey60"), text = ggplot2::element_text(size = 15), panel.grid.major.x = ggplot2::element_blank(), panel.grid.minor = ggplot2::element_blank(), panel.spacing = ggplot2::unit(1, "lines"), plot.title = ggplot2::element_text(size = ggplot2::rel(1.1), face = "bold", vjust = 2), strip.background = ggplot2::element_rect(fill = "grey80"), axis.ticks.y = ggplot2::element_blank(), legend.position = "none", plot.margin = ggplot2::margin(t = 0.5, r = 1, b = 0.5, l = 0.5, unit = "cm"))
    + ggplot2::ggtitle(plotTitle)
  )

  # save gwas forest plot file
  if (!is.null(outputFolderPath)) {
    print(glue::glue("Based on user's choice, GWAS forest plot file will be generated in {outputFolderPath}"))
    suppressWarnings(
      ggplot2::ggsave(filename = paste0(outputFolderPath, "GWASForestPlot_of_", length(gwas_markerName), "_items_by_", length(gwas_studyName), "_groups_in_", ifelse(keepStudyOrder == TRUE, "original", "alphabetical"), "_order_", "with_ColorMode_", colorMode, ".png"), plot = gwas_forest, device = "png", width = gwas_width, height = gwas_height, dpi = 320, limitsize = FALSE)
    )
  } else {
    print("Based on user's choice, GWAS forest plot file will not be generated")
  }
  print("Run completed, thank you for using gwasforest")

  # return GWAS results and forest plot object
  temp_gwas_forest_returnList = list("GWAS_results" = gwas_results_fullCI, "GWAS_forest_plot" = gwas_forest)
  return(temp_gwas_forest_returnList)
}

# preset global variables for R CMD check
utils::globalVariables(c("CI", "ColorGroup", "Lower", "StudyName", "Upper", "Value"))
