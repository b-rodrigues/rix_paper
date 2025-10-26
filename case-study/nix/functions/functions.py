# This script contains modular helper functions for the Python portion of the pipeline.
# Each function performs a single, distinct task in the ML workflow.

# 1. Load required Python packages
# This is only needed if you run this script by hand,
# in which case, uncomment lines 8 to 11.
# With rixpress, the packages get loaded automatically.
#import pandas as pd
#import pyarrow.feather as feather
#from sklearn.model_selection import train_test_split
#import xgboost as xgb
# This script contains the helper functions for the Python portion of the pipeline.
# It defines the ML model training and prediction logic as a pure function.
# This script contains the helper functions for the Python portion of the pipeline.
# It defines the ML model training and prediction logic as a pure function.

#-------------------------------------------------------------------------------
# Step 1: Feature Engineering
#-------------------------------------------------------------------------------
def prepare_features(simulated_df: pd.DataFrame) -> pd.DataFrame:
    """Takes the raw simulated data and creates lagged features and the target variable."""
    df = simulated_df.copy()

    # Create lagged features
    for col in ['output', 'consumption', 'investment', 'capital', 'technology']:
        df[f'{col}_lag1'] = df[col].shift(1)

    # Drop the first row which now has NaNs
    df.dropna(inplace=True)

    return df

#-------------------------------------------------------------------------------
# Step 2: Data Splitting Functions
#-------------------------------------------------------------------------------
def get_X_train(processed_df: pd.DataFrame):
    """Gets the training features (X_train) from the processed data."""
    features = [col for col in processed_df.columns if '_lag1' in col]
    X = processed_df[features]
    train_size = int(0.75 * len(X))
    return X[:train_size]

def get_y_train(processed_df: pd.DataFrame):
    """Gets the training target (y_train) from the processed data."""
    y = processed_df['output']
    train_size = int(0.75 * len(y))
    return y[:train_size]

def get_X_test(processed_df: pd.DataFrame):
    """Gets the testing features (X_test) from the processed data."""
    features = [col for col in processed_df.columns if '_lag1' in col]
    X = processed_df[features]
    train_size = int(0.75 * len(X))
    return X[train_size:]

def get_y_test(processed_df: pd.DataFrame):
    """Gets the testing target (y_test) from the processed data."""
    y = processed_df['output']
    train_size = int(0.75 * len(y))
    return y[train_size:]

#-------------------------------------------------------------------------------
# Step 3: Model Training
#-------------------------------------------------------------------------------
def train_model(X_train: pd.DataFrame, y_train: pd.Series):
    """Initializes and trains the XGBoost model."""
    model = xgb.XGBRegressor(
        objective='reg:squarederror',
        n_estimators=100,
        learning_rate=0.1,
        max_depth=3,
        random_state=42
    )
    model.fit(X_train, y_train)
    return model

#-------------------------------------------------------------------------------
# Step 4: Prediction
#-------------------------------------------------------------------------------
def make_predictions(model, X_test: pd.DataFrame):
    """Makes predictions on the test set using the trained model."""
    return model.predict(X_test)

#-------------------------------------------------------------------------------
# Step 5: Format Final Results
#-------------------------------------------------------------------------------
def format_results(y_test: pd.Series, predictions) -> pd.DataFrame:
    """Combines test data and predictions into a final DataFrame for R."""
    results_df = pd.DataFrame({
        'period': y_test.index,
        'actual_output': y_test.values,
        'predicted_output': predictions
    })
    return results_df

#-------------------------------------------------------------------------------
# Encoder Function (for saving the final output)
#-------------------------------------------------------------------------------
def save_arrow(df: pd.DataFrame, path: str):
    """Encoder function to save a pandas DataFrame to an Arrow file."""
    feather.write_feather(df, path)
