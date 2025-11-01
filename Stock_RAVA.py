"""
Stock RAVA - Risk And Volatility Analysis Dashboard
LINUX version 1.0.0
Streamlit Web Application for comprehensive stock volatility and risk analysis.
RAVA stands for: Risk And Volatility Analysis

This interactive dashboard allows users to analyze any stock ticker's volatility and risk metrics.
Run with: streamlit run Stock_RAVA.py
"""
import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime
import yfinance as yf
import ffn
import quantstats as qs
import warnings

warnings.filterwarnings('ignore')

# Configuration
RISK_FREE_RATE = 0.025  # 2.5% annual risk-free rate

# Page configuration
st.set_page_config(
    page_title="Stock Risk & Volatility Analysis",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
    <style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        padding: 1rem 0;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
    }
    </style>
""", unsafe_allow_html=True)

@st.cache_data(ttl=3600)  # Cache for 1 hour
def download_data(ticker, start_date=None):
    """Download historical data for the given ticker"""
    original_ticker = ticker
    
    # For index-like tickers (GSPC, DJI, etc.), automatically try with '^' prefix first
    # Common index tickers that need '^' prefix on Yahoo Finance
    index_tickers = ['GSPC', 'DJI', 'IXIC', 'RUT', 'VIX']
    if ticker.upper() in [t.upper() for t in index_tickers] and not ticker.startswith('^'):
        ticker = '^' + ticker
    
    try:
        # Try downloading with the provided ticker
        # auto_adjust=True ensures prices are adjusted for splits and dividends
        if start_date:
            data = yf.download(ticker, start=start_date, interval="1d", progress=False, auto_adjust=True)
        else:
            data = yf.download(ticker, period="max", interval="1d", progress=False, auto_adjust=True)
        
        # If download failed and ticker doesn't start with '^', try adding it
        if (data.empty or len(data) == 0) and not ticker.startswith('^'):
            ticker_with_caret = '^' + ticker
            try:
                if start_date:
                    data = yf.download(ticker_with_caret, start=start_date, interval="1d", progress=False, auto_adjust=True)
                else:
                    data = yf.download(ticker_with_caret, period="max", interval="1d", progress=False, auto_adjust=True)
                if not data.empty and len(data) > 0:
                    ticker = ticker_with_caret
            except:
                pass
        
        if data.empty or len(data) == 0:
            return None, original_ticker, f"No data available for ticker: {original_ticker}. Try using '^{original_ticker}' for indices."
        
        # Filter S&P 500 data to start from actual creation date (March 4, 1957)
        if ticker.upper() in ['^GSPC', 'GSPC']:
            if len(data) > 0 and data.index[0] < pd.Timestamp('1957-03-04'):
                data = data[data.index >= '1957-03-04']
        
        # Handle multi-level columns
        if isinstance(data.columns, pd.MultiIndex):
            data.columns = data.columns.get_level_values(0)
        
        return data, ticker, None
    except Exception as e:
        error_msg = str(e)
        if "Not Found" in error_msg or "delisted" in error_msg.lower():
            if not original_ticker.startswith('^'):
                return None, original_ticker, f"Ticker '{original_ticker}' not found. For indices, try '^{original_ticker}'."
        return None, original_ticker, f"Error downloading data: {error_msg}"

def clean_data(raw_data):
    """Clean and preprocess the data"""
    df = raw_data.copy()
    
    # Reset index if Date is in index
    if isinstance(raw_data.index, pd.DatetimeIndex):
        df = raw_data.reset_index()
        if 'Date' not in df.columns:
            df['Date'] = raw_data.index
    else:
        df = raw_data.copy()
    
    # Ensure Date column exists
    if 'Date' not in df.columns:
        df.reset_index(inplace=True)
        if 'Date' not in df.columns:
            df['Date'] = df.index
    
    # Convert Date to datetime if needed
    df['Date'] = pd.to_datetime(df['Date'])
    
    # Select and rename columns
    # When auto_adjust=True, 'Close' is already adjusted
    # But if 'Adj Close' exists and is different, prefer it for maximum accuracy
    if 'Adj Close' in df.columns:
        df['Close'] = df['Adj Close']  # Use adjusted close for all calculations
    
    required_cols = ['Date', 'Open', 'High', 'Low', 'Close', 'Volume']
    for col in required_cols:
        if col not in df.columns and col != 'Date':
            df[col] = np.nan
    
    df = df[required_cols].copy()
    df = df.dropna(subset=['Close', 'Date'])
    
    # Fill missing values
    df['Volume'] = df['Volume'].fillna(0)
    for col in ['Open', 'High', 'Low']:
        df[col] = df[col].fillna(df['Close'])
    
    # Remove duplicates
    df = df.drop_duplicates(subset='Date').reset_index(drop=True)
    
    # Sort by date
    df = df.sort_values('Date').reset_index(drop=True)
    
    return df

def calculate_returns(df):
    """Calculate daily returns"""
    df['Daily_Return'] = df['Close'].pct_change()
    df = df.dropna().reset_index(drop=True)
    return df

def calculate_volatility(df):
    """Calculate rolling volatility"""
    windows = [30, 60, 252]
    
    for window in windows:
        rolling_std = df['Daily_Return'].rolling(window=window).std()
        annualized_vol = rolling_std * np.sqrt(252)
        df[f'Volatility_{window}d'] = annualized_vol * 100
    
    return df

def calculate_drawdown(df):
    """Calculate drawdown metrics using ffn"""
    prices_series = pd.Series(df['Close'].values, index=df['Date'])
    dd_series_ffn = ffn.to_drawdown_series(prices_series)
    df['Drawdown'] = dd_series_ffn.values * 100
    df['Running_Max'] = df['Close'].expanding().max()
    df['Max_Drawdown'] = df['Drawdown'].expanding().min()
    return df

def find_major_drawdowns(df, threshold=20):
    """Find all major drawdown periods (>= threshold %)"""
    major_drawdowns = []
    current_peak_idx = 0
    current_peak_price = df.loc[0, 'Close']
    in_drawdown = False
    drawdown_start_idx = None
    
    for i in range(1, len(df)):
        if df.loc[i, 'Close'] > current_peak_price:
            # New peak reached
            if in_drawdown:
                # End of drawdown period
                trough_idx = df.loc[drawdown_start_idx:i, 'Close'].idxmin()
                trough_price = df.loc[trough_idx, 'Close']
                drawdown_pct = ((trough_price - df.loc[drawdown_start_idx, 'Close']) / 
                               df.loc[drawdown_start_idx, 'Close']) * 100
                
                if abs(drawdown_pct) >= threshold:
                    major_drawdowns.append({
                        'Peak_Date': df.loc[drawdown_start_idx, 'Date'],
                        'Trough_Date': df.loc[trough_idx, 'Date'],
                        'Peak_Price': df.loc[drawdown_start_idx, 'Close'],
                        'Trough_Price': trough_price,
                        'Drawdown_Pct': drawdown_pct,
                        'Duration_Days': (df.loc[trough_idx, 'Date'] - df.loc[drawdown_start_idx, 'Date']).days
                    })
                in_drawdown = False
            
            current_peak_idx = i
            current_peak_price = df.loc[i, 'Close']
        
        elif not in_drawdown and df.loc[i, 'Close'] < current_peak_price * 0.95:
            # Entering drawdown
            in_drawdown = True
            drawdown_start_idx = current_peak_idx
    
    return pd.DataFrame(major_drawdowns)

def calculate_recovery(df, drawdowns_df):
    """Calculate recovery time for each major drawdown"""
    recovery_analysis = []
    
    for _, dd in drawdowns_df.iterrows():
        trough_date = dd['Trough_Date']
        peak_price = dd['Peak_Price']
        
        # Find when price recovered to peak level
        recovery_data = df[df['Date'] > trough_date]
        recovery = recovery_data[recovery_data['Close'] >= peak_price]
        
        if not recovery.empty:
            recovery_date = recovery.iloc[0]['Date']
            recovery_days = (recovery_date - trough_date).days
            recovery_months = recovery_days / 30.44  # Average days per month
            
            recovery_analysis.append({
                'Drawdown_Pct': dd['Drawdown_Pct'],
                'Drawdown_Duration_Days': dd['Duration_Days'],
                'Recovery_Days': recovery_days,
                'Recovery_Months': round(recovery_months, 1),
                'Trough_Date': trough_date,
                'Recovery_Date': recovery_date
            })
    
    return pd.DataFrame(recovery_analysis)

def calculate_risk_metrics(df, ticker):
    """Calculate comprehensive risk metrics"""
    prices_series = pd.Series(df['Close'].values, index=df['Date'])
    returns_series = pd.Series(df['Daily_Return'].values, index=df['Date'])
    
    stats = ffn.calc_stats(prices_series)
    total_return_ffn = stats.total_return
    
    annualized_return = qs.stats.cagr(returns_series)
    annualized_volatility = qs.stats.volatility(returns_series, periods=252)
    sharpe_ratio = qs.stats.sharpe(returns_series, rf=RISK_FREE_RATE, periods=252)
    sortino_ratio = qs.stats.sortino(returns_series, rf=RISK_FREE_RATE, periods=252)
    max_dd_quantstats = qs.stats.max_drawdown(returns_series)
    
    years = (df['Date'].iloc[-1] - df['Date'].iloc[0]).days / 365.25
    excess_return = annualized_return - RISK_FREE_RATE
    
    return {
        'total_return': total_return_ffn,
        'cagr': annualized_return,
        'volatility': annualized_volatility,
        'sharpe': sharpe_ratio,
        'sortino': sortino_ratio,
        'max_drawdown': max_dd_quantstats,
        'years': years,
        'excess_return': excess_return,
        'risk_free_rate': RISK_FREE_RATE
    }

def create_dashboard(df, risk_metrics, ticker, recovery_df):
    """Create comprehensive visualization dashboard"""
    fig = plt.figure(figsize=(18, 12))
    gs = fig.add_gridspec(3, 2, hspace=0.3, wspace=0.3)
    
    # 1. Price with volatility overlay
    ax1 = fig.add_subplot(gs[0, :])
    ax1_twin = ax1.twinx()
    ax1.plot(df['Date'], df['Close'], label=f'{ticker} Price', color='steelblue', linewidth=1.5)
    ax1_twin.plot(df['Date'], df['Volatility_252d'], label='252-day Volatility', 
                 color='orange', alpha=0.7, linewidth=1.5)
    ax1.set_ylabel('Price', fontsize=11, color='steelblue')
    ax1_twin.set_ylabel('Volatility (%)', fontsize=11, color='orange')
    ax1.set_title('Price and Volatility Over Time', fontsize=12, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    ax1.legend(loc='upper left')
    ax1_twin.legend(loc='upper right')
    
    # 2. Drawdown
    ax2 = fig.add_subplot(gs[1, 0])
    ax2.fill_between(df['Date'], df['Drawdown'], 0, color='red', alpha=0.3)
    ax2.set_ylabel('Drawdown (%)', fontsize=11)
    ax2.set_title('Drawdown from Peak', fontsize=12, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    
    # 3. Volatility distribution
    ax3 = fig.add_subplot(gs[1, 1])
    ax3.hist(df['Volatility_252d'].dropna(), bins=50, color='steelblue', alpha=0.7, edgecolor='black')
    ax3.set_xlabel('252-day Volatility (%)', fontsize=11)
    ax3.set_ylabel('Frequency', fontsize=11)
    ax3.set_title('Distribution of 252-day Volatility', fontsize=12, fontweight='bold')
    ax3.grid(True, axis='y', alpha=0.3)
    
    # 4. Returns distribution
    ax4 = fig.add_subplot(gs[2, 0])
    ax4.hist(df['Daily_Return'] * 100, bins=100, color='green', alpha=0.7, edgecolor='black')
    ax4.set_xlabel('Daily Return (%)', fontsize=11)
    ax4.set_ylabel('Frequency', fontsize=11)
    ax4.set_title('Distribution of Daily Returns', fontsize=12, fontweight='bold')
    ax4.grid(True, axis='y', alpha=0.3)
    
    # 5. Rolling volatility comparison OR Drawdown vs Recovery
    ax5 = fig.add_subplot(gs[2, 1])
    if len(recovery_df) > 0:
        ax5.scatter(recovery_df['Drawdown_Pct'], recovery_df['Recovery_Months'],
                   s=100, alpha=0.6, color='red', edgecolors='black')
        ax5.set_xlabel('Drawdown Magnitude (%)', fontsize=11)
        ax5.set_ylabel('Recovery Time (Months)', fontsize=11)
        ax5.set_title('Drawdown vs Recovery Time', fontsize=12, fontweight='bold')
        ax5.grid(True, alpha=0.3)
    else:
        ax5.plot(df['Date'], df['Volatility_30d'], label='30-day', alpha=0.7, linewidth=1)
        ax5.plot(df['Date'], df['Volatility_60d'], label='60-day', alpha=0.7, linewidth=1)
        ax5.plot(df['Date'], df['Volatility_252d'], label='252-day', alpha=0.7, linewidth=1)
        ax5.set_ylabel('Volatility (%)', fontsize=11)
        ax5.set_title('Rolling Volatility Comparison', fontsize=12, fontweight='bold')
        ax5.legend()
        ax5.grid(True, alpha=0.3)
    
    plt.suptitle(f'{ticker} Comprehensive Risk Analysis Dashboard', 
                 fontsize=16, fontweight='bold', y=0.995)
    
    return fig

def main():
    """Main Streamlit application"""
    # Header
    st.markdown('<h1 class="main-header">📊 Stock Risk & Volatility Analysis Dashboard</h1>', unsafe_allow_html=True)
    st.markdown("---")
    
    # Sidebar for input
    with st.sidebar:
        st.header("⚙️ Configuration")
        
        # Ticker input
        ticker = st.text_input(
            "Enter Stock Ticker",
            value="^GSPC",
            help="Examples: ^GSPC (S&P 500), AAPL (Apple), MSFT (Microsoft), TSLA (Tesla)"
        )
        
        st.markdown("**Note:** For indices, use '^' prefix (e.g., ^GSPC, ^DJI)")
        
        # Analyze button
        analyze_button = st.button("🚀 Run Analysis", type="primary", use_container_width=True)
        
        st.markdown("---")
        st.markdown("### 📚 About")
        st.markdown("""
        This dashboard provides comprehensive risk and volatility analysis for any stock or index.
        
        **Features:**
        - Volatility analysis
        - Drawdown calculations
        - Risk-adjusted returns (Sharpe, Sortino)
        - Interactive visualizations
        """)
    
    # Main content area
    if analyze_button:
        # Download data
        with st.spinner(f"Downloading data for {ticker}..."):
            # For S&P 500, use start date filter
            if ticker.upper() in ['^GSPC', 'GSPC']:
                raw_data, actual_ticker, error = download_data(ticker, start_date='1957-03-04')
            else:
                raw_data, actual_ticker, error = download_data(ticker)
            
            if error:
                st.error(f"❌ Error: {error}")
                st.info("💡 Try using a different ticker or check if the ticker symbol is correct.")
                return
        
        if raw_data is None or raw_data.empty:
            st.error(f"❌ No data available for ticker: {ticker}")
            return
        
        # Show data info
        st.success(f"✅ Data downloaded successfully for **{actual_ticker}**!")
        
        # Process data
        with st.spinner("Processing data and calculating metrics..."):
            df = clean_data(raw_data)
            df = calculate_returns(df)
            df = calculate_volatility(df)
            df = calculate_drawdown(df)
            drawdowns_df = find_major_drawdowns(df, threshold=20)
            recovery_df = calculate_recovery(df, drawdowns_df)
            risk_metrics = calculate_risk_metrics(df, actual_ticker)
        
        # Display key metrics
        st.markdown("### 📈 Key Metrics")
        
        col1, col2, col3, col4, col5 = st.columns(5)
        
        with col1:
            st.metric("CAGR", f"{risk_metrics['cagr']*100:.2f}%")
        with col2:
            st.metric("Volatility", f"{risk_metrics['volatility']*100:.2f}%")
        with col3:
            st.metric("Sharpe Ratio", f"{risk_metrics['sharpe']:.3f}")
        with col4:
            st.metric("Sortino Ratio", f"{risk_metrics['sortino']:.3f}")
        with col5:
            st.metric("Max Drawdown", f"{abs(risk_metrics['max_drawdown'])*100:.2f}%")
        
        st.markdown("---")
        
        # Display dashboard
        st.markdown("### 📊 Analysis Dashboard")
        fig = create_dashboard(df, risk_metrics, actual_ticker, recovery_df)
        st.pyplot(fig)
        plt.close(fig)
        
        # Detailed metrics table
        st.markdown("---")
        st.markdown("### 📋 Detailed Risk Metrics")
        
        metrics_df = pd.DataFrame({
            'Metric': [
                'Total Return',
                'Annualized Return (CAGR)',
                'Annualized Volatility',
                'Risk-Free Rate',
                'Excess Return',
                'Sharpe Ratio',
                'Sortino Ratio',
                'Maximum Drawdown',
                'Years Analyzed',
                'Total Trading Days'
            ],
            'Value': [
                f"{risk_metrics['total_return']*100:.2f}%",
                f"{risk_metrics['cagr']*100:.2f}%",
                f"{risk_metrics['volatility']*100:.2f}%",
                f"{risk_metrics['risk_free_rate']*100:.2f}%",
                f"{risk_metrics['excess_return']*100:.2f}%",
                f"{risk_metrics['sharpe']:.3f}",
                f"{risk_metrics['sortino']:.3f}",
                f"{abs(risk_metrics['max_drawdown'])*100:.2f}%",
                f"{risk_metrics['years']:.1f}",
                f"{len(df):,}"
            ]
        })
        
        st.table(metrics_df)  # Using st.table instead of st.dataframe to avoid pyarrow dependency
        
        # Drawdown analysis
        if len(drawdowns_df) > 0:
            st.markdown("---")
            st.markdown("### 📉 Major Drawdown Events (≥20%)")
            st.table(drawdowns_df)  # Using st.table instead of st.dataframe to avoid pyarrow dependency
        
        if len(recovery_df) > 0:
            st.markdown("### ⏱️ Recovery Analysis")
            st.table(recovery_df)  # Using st.table instead of st.dataframe to avoid pyarrow dependency
        
        # Data summary
        st.markdown("---")
        st.markdown("### 📅 Data Summary")
        
        col1, col2 = st.columns(2)
        with col1:
            st.info(f"**Date Range:** {df['Date'].min().strftime('%Y-%m-%d')} to {df['Date'].max().strftime('%Y-%m-%d')}")
        with col2:
            st.info(f"**Analysis Period:** {risk_metrics['years']:.1f} years")
        
        # Download button for data
        st.markdown("---")
        csv = df[['Date', 'Close', 'Daily_Return', 'Volatility_252d', 'Drawdown']].to_csv(index=False)
        st.download_button(
            label="📥 Download Analysis Data (CSV)",
            data=csv,
            file_name=f"{actual_ticker}_analysis_data.csv",
            mime="text/csv"
        )
    
    else:
        # Welcome screen
        st.markdown("""
        ### 👋 Welcome to the Stock Risk & Volatility Analysis Dashboard!
        
        **Get Started:**
        1. Enter a stock ticker symbol in the sidebar (e.g., ^GSPC, AAPL, MSFT)
        2. Click the "🚀 Run Analysis" button
        3. View comprehensive risk metrics and visualizations
        
        **What You'll Get:**
        - 📊 Interactive risk analysis dashboard
        - 📈 Volatility trends and distributions
        - 📉 Drawdown analysis
        - 💼 Risk-adjusted return metrics (Sharpe, Sortino ratios)
        - 📋 Detailed metrics table
        
        **Popular Tickers to Try:**
        - **^GSPC** - S&P 500 Index
        - **AAPL** - Apple Inc.
        - **MSFT** - Microsoft Corporation
        - **TSLA** - Tesla Inc.
        - **GOOGL** - Alphabet Inc.
        """)

if __name__ == "__main__":
    main()

