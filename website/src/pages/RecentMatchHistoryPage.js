import React, { Component } from 'react';
import './RecentMatchHistoryPage.css';
import MatchHistory from '../components/MatchHistory';
import Page from './Page';

class RecentMatchHistoryPage extends Component {
    render() {
        return (
            <div className="RecentMatchHistoryPage">
                <Page title="Recent Matches">
                    <MatchHistory />
                </Page>
            </div>
        );
    }
}
export default RecentMatchHistoryPage;
