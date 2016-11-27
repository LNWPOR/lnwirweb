<%@include file="jsp/header.jsp"%>
<%@page pageEncoding="UTF-8"%>
<%@include file="jsp/navbar.jsp"%>
<%@include file="jsp/info-section.jsp"%>
<%@include file="jsp/search-section.jsp"%>
<%@ page import = "javax.servlet.*, javax.servlet.http.*, java.io.*, java.net.URLEncoder, java.net.URLDecoder, java.nio.file.Paths, org.apache.lucene.analysis.Analyzer, org.apache.lucene.analysis.TokenStream, org.apache.lucene.analysis.standard.StandardAnalyzer, org.apache.lucene.analysis.th.ThaiAnalyzer, org.apache.lucene.document.Document, org.apache.lucene.index.DirectoryReader, org.apache.lucene.index.IndexReader, org.apache.lucene.queryparser.classic.QueryParser, org.apache.lucene.queryparser.classic.ParseException, org.apache.lucene.search.IndexSearcher, org.apache.lucene.search.Query, org.apache.lucene.search.ScoreDoc, org.apache.lucene.search.TopDocs, org.apache.lucene.search.highlight.Highlighter, org.apache.lucene.search.highlight.InvalidTokenOffsetsException, org.apache.lucene.search.highlight.QueryScorer, org.apache.lucene.search.highlight.SimpleFragmenter, org.apache.lucene.store.FSDirectory, java.util.HashMap, java.util.Map ,java.util.List, java.util.LinkedList, java.util.Collections, java.util.Comparator, java.util.LinkedHashMap, java.util.ArrayList" %>
<%!
public String escapeHTML(String s) {
  s = s.replaceAll("&", "&amp;");
  s = s.replaceAll("<", "&lt;");
  s = s.replaceAll(">", "&gt;");
  s = s.replaceAll("\"", "&quot;");
  s = s.replaceAll("'", "&apos;");
  return s;
}
%>
<%!
private static Map<Document, Float> sortByValue(Map<Document, Float> unsortMap) {
  // 1. Convert Map to List of Map
  List<Map.Entry<Document, Float>> list =
          new LinkedList<Map.Entry<Document, Float>>(unsortMap.entrySet());

  // 2. Sort list with Collections.sort(), provide a custom Comparator
  //    Try switch the o1 o2 position for a different order
  Collections.sort(list, new Comparator<Map.Entry<Document, Float>>() {
      public int compare(Map.Entry<Document, Float> o1,
                         Map.Entry<Document, Float> o2) {
          return (o1.getValue()).compareTo(o2.getValue());
      }
  });

  // 3. Loop the sorted list and put it into a new insertion order Map LinkedHashMap
  Map<Document, Float> sortedMap = new LinkedHashMap<Document, Float>();
  for (Map.Entry<Document, Float> entry : list) {
      sortedMap.put(entry.getKey(), entry.getValue());
  }

  /*
  //classic iterator example
  for (Iterator<Map.Entry<String, Integer>> it = list.iterator(); it.hasNext(); ) {
      Map.Entry<String, Integer> entry = it.next();
      sortedMap.put(entry.getKey(), entry.getValue());
  }*/

  return sortedMap;
}

/*
public static <K, V> void printMap(Map<K, V> map) {
  for (Map.Entry<K, V> entry : map.entrySet()) {
      System.out.println("Key : " + entry.getKey()
              + " Value : " + entry.getValue());
  }
}
*/
%>
<%
boolean error = false;                  //used to control flow for error messages
String indexName = indexLocation;       //local copy of the configuration variable
IndexSearcher searcher = null;          //the searcher used to open/search the index
Query query = null;                     //the Query created by the QueryParser
TopDocs hits = null;                    //the search results
int startindex = 0;                     //the first index displayed on this page
int maxpage    = 50;                    //the maximum items displayed on this page
String queryString = null;              //the query entered in the previous page
String startVal    = null;              //string version of startindex
String maxresults  = null;              //string version of maxpage
int thispage = 0;                       //used for the for/next either maxpage or
                                        //hits.totalHits - startindex - whichever is
                                        //less
String search_method = null;
float alpha = 0.0f;
float beta = 0.0f;

try {
  IndexReader reader = DirectoryReader.open(FSDirectory.open(Paths.get(indexName)));
  searcher = new IndexSearcher(reader);         //create an indexSearcher for our page
                                                //NOTE: this operation is slow for large
                                                //indices (much slower than the search itself)
                                                //so you might want to keep an IndexSearcher 
                                                //open
                                                
} catch (Exception e) {                         //any error that happens is probably due
                                                //to a permission problem or non-existant
                                                //or otherwise corrupt index
%>
  <p>ERROR opening the Index - contact sysadmin!</p>
  <p>Error message: <%=escapeHTML(e.getMessage())%></p>   
<%    
  error = true;                                         //don't do anything up to the footer
}
%>
<%
if (error == false ) {                                  //did we open the index?
  //queryString = URLDecoder.decode(request.getParameter("query"),"UTF-8"); //get the search criteria
  queryString = request.getParameter("query");          //get the search criteria
  startVal    = request.getParameter("startat");        //get the start index
  maxresults  = request.getParameter("maxresults");     //get max results per page
  search_method = request.getParameter("search_method");
  alpha = Float.parseFloat(request.getParameter("alpha"));
  beta = Float.parseFloat(request.getParameter("beta"));
  try {
    maxpage    = Integer.parseInt(maxresults);    //parse the max results first
    startindex = Integer.parseInt(startVal);      //then the start index

    
  } catch (Exception e) { }                             //we don't care if something happens we'll just start at 0
                                                        //or end at 50
  if (queryString == null)
    throw new ServletException("no query "+             //if you don't have a query then
                               "specified");            //you probably played on the 
                                                        //query string so you get the 
                                                        //treatment
  //Analyzer analyzer = new StandardAnalyzer(Version.LUCENE_CURRENT); //construct our usual analyzer
  Analyzer analyzer = new StandardAnalyzer();
  //Analyzer analyzer = new ThaiAnalyzer();
  try {
    QueryParser qp = new QueryParser("contents", analyzer);
    query = qp.parse(queryString.trim());         
%>
    <div class="notification is-info">
      <div class="container">
        <h6 class="subtitle">Searching for
          <span class="title is-4">"<%=queryString%>" </span>
          by 
          <span class="title is-4"> "<%=search_method%>".
<%
    if(search_method.equals("MixScore")){
%>
      alpha = <%=alpha%>, beta = <%=beta%>
<%
    }
%>
          
        </h6>
      </div>
    </div>
<%
  } catch (ParseException e) {                          //parse the
                                                        //query and construct the Query
                                                        //object
                                                        //if it's just "operator error"
                                                        //send them a nice error HTML                              
%>
    <!-- <p>Error while parsing query: <%=escapeHTML(e.getMessage())%></p> -->
    <div class="notification is-danger">
      <div class="container">
        <h6 class="subtitle">Prease Type a keyword before search.</h6>
      </div>
    </div>
<%
    error = true; //don't bother with the rest of the page
  }
}
%>
<%
if (error == false && searcher != null) {               // if we've had no errors
                                                        // searcher != null was to handle
                                                        // a weird compilation bug 
  thispage = maxpage;                                   // default last element to maxpage
  hits = searcher.search(query, maxpage + startindex);  // run the query 
  if (hits.totalHits == 0) {                            // if we got no results tell the user
%>
    <%@include file="jsp/cannotFind.jsp"%>
<%
    error = true;                                         // don't bother with the rest of the
                                                          // page
  }
}

if(search_method.equals("MixScore") && alpha + beta != 1.0f){
  error = true;
%>
  <div class="notification is-danger">
    <div class="container">
      <h6 class="subtitle">The sum of alpha and beta must equal to 1. Prease try again.</h6>
    </div>
  </div>
<%
}

if (error == false && searcher != null) {                   
  //Create doc map that sort by PageRank score of each document.
  Map<Document, Float> docPageRankMap = new HashMap<Document, Float>();
  /*for(int i = 0; i< hits.totalHit - 1; i++){
    Document doc = searcher.doc(i);
    if(doc.get("PageRank") != null){
      docPageRankMap.put(doc, Float.parseFloat(doc.get("PageRank")));
    }
    else{
      continue;
    }
  }*/
  for(int i = 0; i< hits.scoreDocs.length - 1; i++){
    Document doc = searcher.doc(hits.scoreDocs[i].doc);
    if(doc.get("PageRank") != null){
      docPageRankMap.put(doc, Float.parseFloat(doc.get("PageRank")));
    }
    else{
      continue;
    }
  }
  Map<Document, Float> docSortByPageRankMap = sortByValue(docPageRankMap);
  List<Document> docSortByPageRankKeyList = new ArrayList<Document>(docSortByPageRankMap.keySet());

  //Create doc map that sort by mix score of each document.
  Map<Document, Float> docMixScoreMap = new HashMap<Document, Float>();
  for(int i = 0; i < hits.scoreDocs.length; i++){
    Document doc = searcher.doc(hits.scoreDocs[i].doc);
    if(doc.get("PageRank") != null){
      //for(int j = 0; j < hits.scoreDocs.length; j++){
        //if(doc.get("URL").equals(searcher.doc(hits.scoreDocs[j].doc).get("URL"))){
          float pr = Float.parseFloat(doc.get("PageRank"));
          float sim = hits.scoreDocs[i].score;
          //out.println(doc.get("URL"));
          //out.println("gg");
          //out.println(searcher.doc(hits.scoreDocs[j].doc).get("URL"));
          //float alpha = 0.5f; //where 0 ≤ α,β ≤ 1 and α+β = 1
          //float beta = 0.5f;
          float mixScore = alpha*sim + beta*pr;
          docMixScoreMap.put(doc, mixScore);
        //}
      //}
      /*if(i < hits.scoreDocs.length){
        float pr = Float.parseFloat(doc.get("PageRank"));
        float sim = hits.scoreDocs[i].score;
        out.println(doc.get("URL"));
        out.println("gg");
        out.println(searcher.doc(hits.scoreDocs[i].doc).get("URL"));
        //float alpha = 0.5f; //where 0 ≤ α,β ≤ 1 and α+β = 1
        //float beta = 0.5f;
        float mixScore = alpha*sim + (1-alpha)*pr;
        docMixScoreMap.put(doc, mixScore);
      }else{
        continue;
      }*/
    }else{
      continue;
    }
  }
  Map<Document, Float> docSortByMixScoreMap = sortByValue(docMixScoreMap);
  List<Document> docSortByMixScoreKeyList = new ArrayList<Document>(docSortByMixScoreMap.keySet());

  if ((startindex + maxpage) > hits.totalHits) {
          thispage = hits.totalHits - startindex;      // set the max index to maxpage or last
  }                                                   // actual search result whichever is less

  for (int i = startindex; i < (thispage + startindex); i++) {  // for each element
    //Document doc = searcher.doc(hits.scoreDocs[i].doc);                     //get the next document 
    Document doc;
    String scoreShow;
    if(search_method.equals("Similarity")){
      if(searcher.doc(hits.scoreDocs[i].doc).get("PageRank") != null){
        doc = searcher.doc(hits.scoreDocs[i].doc);
        scoreShow = Float.toString(hits.scoreDocs[i].score); 
      }
      else{
        continue;
      }
    }else if (search_method.equals("PageRank")){ //search_method.equals("PageRank")
      if(docSortByPageRankMap.size() == 0){
%>
        <%@include file="jsp/cannotFind.jsp"%>
<%
        break;
      }                     
      int revertDocIndex = docSortByPageRankMap.size() - 1 - i;
      if(revertDocIndex < 0){
        break;
      }
      if(docSortByPageRankKeyList.get(revertDocIndex) != null){
        doc = docSortByPageRankKeyList.get(revertDocIndex);
        scoreShow = doc.get("PageRank");
      }else{
        continue;
      }
    }else{ //search_method.equals("MixScore") 
      if(docSortByPageRankMap.size() == 0){
%>
        <%@include file="jsp/cannotFind.jsp"%>
<%
        break;
      }   
      int revertDocIndex = docSortByMixScoreMap.size() - 1 - i;
      if(revertDocIndex < 0){
        break;
      }
      if(docSortByMixScoreKeyList.get(revertDocIndex) != null){
        doc = docSortByMixScoreKeyList.get(revertDocIndex);
        scoreShow = Float.toString(docSortByMixScoreMap.get(doc));
      }else{
        continue;
      }
    }
    
    String doctitle = doc.get("title");            //get its title
    String path = doc.get("path");
    String docContents = doc.get("docContents");
    String snippet = doc.get("snippet");
    String url = doc.get("URL");
    //String pageRank = doc.get("PageRank");

    //out.println(docContents);

    if (path != null && path.startsWith("../webapps/")) { // strip off ../webapps prefix if present
      path = path.substring(10);
    }
    if ((doctitle == null) || doctitle.equals("")) //use the path if it has no title
      doctitle = path;
%>
    <div class="box">
      <article class="media">
        
        <div class="media-left">
          <h1 class="title"><%=i+1%></h1>
          <h1 class="subtitle"><%=search_method%></h1>
          <h1 class="subtitle"><%=scoreShow%></h1>
        </div>

        <div class="media-content">
          <div class="content">
            <a href=<%=url%> >
              <h4 class="title is-4"  style="color: blue;">
                <%=doctitle%>
              <h4>
            </a>
            <h4 class="subtitle">
              <!-- <%=snippet%> -->
<%
    int indexDocs = docContents.indexOf(queryString); 
    if(indexDocs != -1){
      String docContentsNoURLandTitle = docContents.substring(url.length() + doc.get("title").length(), docContents.length());
      int index = docContentsNoURLandTitle.indexOf(queryString);
      String newSnippet = "";
      int range = 500;
      int startIndex;
      int endIndex;
      
      //check range
      if(index - range < 0){
        startIndex = 0;
      }else{
        startIndex = index - range;
      }
      if(index + queryString.length() + range > docContentsNoURLandTitle.length() - 1){
        endIndex = docContentsNoURLandTitle.length() - 1;
      }else{
        endIndex = index + queryString.length() + range;
      }
      
      //insert highlight
      for (int j = startIndex; j < endIndex; j++) {
        if(j == index - 1){
          newSnippet += docContentsNoURLandTitle.charAt(j);
          newSnippet += "<B style=\"color: red;\">";
        }
        else if(j == index + queryString.length()){
          newSnippet += "</B>";
          newSnippet += docContentsNoURLandTitle.charAt(j);
        }
        else{
          newSnippet += docContentsNoURLandTitle.charAt(j);
        }
      }
%>
      <%=newSnippet%>
<%
    }else{
      if (snippet != null) {
%>
        <%=snippet%>
<%
      }else{
%>
        No Snippet
<%                            
      }
    }    
%>
            </h4>
            <a href=<%=url%> >
              <h4 class="subtitle" style="color: green;">
                <%=url%>
              </h4>
            </a>
          </div>
        </div>
      </article>
    </div>
                
<%
  }
%>
<%                
  if ( (startindex + maxpage) < hits.totalHits) {   //if there are more results...display 
                                                    //the more link
    String moreurl="results.jsp?query=" + queryString +
                   //URLEncoder.encode(queryString) +  //construct the "more" link
                   "&amp;maxresults=" + maxpage + 
                   "&amp;startat=" + (startindex + maxpage) +
                   "&amp;search_method=" + search_method +
                   "&amp;alpha=" + alpha +
                   "&amp;beta=" + beta;
%>
    <div class="box">
      <article class="media">
        <div class="media-content">
          <div class="content">
            <center>
              <a href="<%=moreurl%>" class="button is-info is-medium">
                More Results
              </a>
            </center>
          </div>
        </div>
      </article>
    </div>
<%
  }
%>
<%       
}        //then include our footer.
         //if (searcher != null)
         //       searcher.close();
%>
<%@include file="jsp/members-modal.jsp"%>
<%@include file="jsp/footer.jsp"%>        
