import java.util.Arrays;
import java.util.Collections;
import java.util.Random;
import java.awt.Point;

String[] phrases; //contains all of the phrases
int totalTrialNum = 2; //the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; //the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; //a running total of the number of errors (when hitting next)
String currentPhrase = ""; //the current target phrase
String currentTyped = ""; //what the user has typed so far
final int DPIofYourDeviceScreen = 131; //you will need to look up the DPI or PPI of your device to make sure you get the right scale!!
//http://en.wikipedia.org/wiki/List_of_displays_by_pixel_density

PImage watch;

// fonts
PFont fontLarge;
PFont fontSmall;

// screen
final int width = 800;
final int height = 800;

// input area
final float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
final float inputAreaX = width/2-sizeOfInputArea/2;
final float inputAreaY = height/2-sizeOfInputArea/2;

// keyboard

final float keyboardHeightFraction = 1;
final float keyboardX = inputAreaX;
final float keyboardY = inputAreaY + (1 - keyboardHeightFraction) * sizeOfInputArea;
final float keyboardWidth = sizeOfInputArea;
final float keyboardHeight = keyboardHeightFraction * sizeOfInputArea;
final String[][] keyboardLayout = {
    {
        "", ""
    },
    {
        "", ""
    },
    {
        "", ""
    },
    {
        "q", "w", "e", "r", "t", "y", "u", "i", "o", "p"
    },
    {
        "a", "s", "d", "f", "g", "h", "j", "k", "l", ""
    },
    {
        "", "z", "x", "c", "v", "b", "n", "m", ""
    },
    {
        "space", "delete"
    }
};
ArrayList<ArrayList<Button>> keyboardButtons = new ArrayList<ArrayList<Button>>();

// keys

final float keyLabelHoriPadding = 3;
final float keyLabelVertPadding = 10;
final float keyLetterPadding = 4;
ArrayList<ArrayList<HighlightedTextLabel>> keyTextLabels = new ArrayList<ArrayList<HighlightedTextLabel>>();

// next button
final int nextButtonX = 350;
final int nextButtonY = 600;
final int nextButtonWidth = 200;
final int nextButtonHeight = 200;

// intellisense module
Intellisense intellisense;


void settings() {
  size(width, height);
}


void setup()
{
    fontLarge = createFont("Courier New", 18);
    fontSmall = createFont("Courier New", 12);

    watch = loadImage("watchhand3smaller.png");
    phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
    intellisense = new Intellisense(phrases);
    Collections.shuffle(Arrays.asList(phrases), new Random()); //randomize the order of the phrases with no seed

    orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device

    // create keyboard buttons
    float currY = keyboardY;
    for (int row = 0; row < keyboardLayout.length; ++row) {
        float currX = keyboardX;
        ArrayList<Button> keyboardButtonsRow = new ArrayList<Button>();
        ArrayList<HighlightedTextLabel> keyTextLabelsRow = new ArrayList<HighlightedTextLabel>();

        for (int col = 0; col < keyboardLayout[row].length; ++col) {
            final int finalRow = row;
            final int finalCol = col;
            ButtonOnClickHandler onClick = new ButtonOnClickHandler() {
                public void call() {
                    System.out.format("Clicked (%d, %d) \n", finalRow, finalCol);

                    if (finalRow == keyboardLayout.length - 1) {
                        // last row (special row)
                        if (finalCol == 0) {
                            currentTyped += " ";
                        }
                        else if (finalCol == 1) {
                            currentTyped = 
                                currentTyped.length() == 0 
                                ? "" 
                                : currentTyped.substring(0, currentTyped.length() - 1);
                        }
                    } else if (finalRow >= 3) {
                        // normal characters
                        currentTyped += keyTextLabels.get(finalRow).get(finalCol).strs[0].toLowerCase();
                    } else { 
                        // suggestion region
                        if (currentTyped.length() > 0 && currentTyped.charAt(currentTyped.length() - 1) != ' ') {
                            // need to remove last word first
                            currentTyped = currentTyped.substring(0, max(currentTyped.lastIndexOf(" "), 0));
                        }
                        currentTyped = currentTyped.trim() + " " + keyTextLabels.get(finalRow).get(finalCol).strs[0].toLowerCase();
                        currentTyped = currentTyped.trim();
                        currentTyped += " ";
                    }
                    triggerIntellisense();
                }
            };
            keyboardButtonsRow.add(new Button(
                currX, 
                currY, 
                keyboardWidth / keyboardLayout[row].length, 
                keyboardHeight / keyboardLayout.length, 
                onClick
            ));
            keyTextLabelsRow.add(new HighlightedTextLabel(
                currX + keyLabelHoriPadding,
                currY + keyLabelVertPadding,
                keyLetterPadding,
                new String[] { keyboardLayout[row][col] }
            ));

            currX += keyboardWidth / keyboardLayout[row].length;
        }

        currY += keyboardHeight / keyboardLayout.length;
        keyboardButtons.add(keyboardButtonsRow);
        keyTextLabels.add(keyTextLabelsRow);
    }

    triggerIntellisense();
}

void draw()
{
    int textX = 200;

    background(255); //clear background
    drawWatch(); //draw watch background
    fill(100);
    rect(inputAreaX, inputAreaY, sizeOfInputArea, sizeOfInputArea); //input area should be 1" by 1"

    if (finishTime!=0)
    {
        fill(128);
        textAlign(CENTER);
        textFont(fontLarge);
        text("Finished", 280, 150);
        return;
    }

    if (startTime==0 & !mousePressed)
    {
        fill(128);
        textAlign(CENTER);
        textFont(fontLarge);
        text("Click to start time!", textX, 150); //display this messsage until the user clicks!
    }

    if (startTime==0 & mousePressed)
    {
        nextTrial(); //start the trials!
    }

    if (startTime!=0)
    {
        int textY = 270;
        boolean isEvenSecond = ((int) (millis() / 1000)) % 2 == 0;
        textFont(fontLarge);
        //feel free to change the size and position of the target/entered phrases and next button 
        textAlign(LEFT); //align the text left
        fill(128);
        text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, textX, textY - 100); //draw the trial count
        fill(128);
        text(" Target: " + currentPhrase, textX, textY - 15); //draw the target string
        text("Entered: " + currentTyped + (isEvenSecond ? "_" : ""), textX, textY); //draw what the user has entered thus far 

        //draw very basic next button
        fill(255, 0, 0);
        rect(nextButtonX, nextButtonY, nextButtonWidth, nextButtonHeight); //draw next button
        fill(255);
        text("NEXT > ", nextButtonX + 50, nextButtonY + 50); //draw next label
    }

    // draw keyboard
    for (int row = 0; row < keyboardButtons.size(); ++row) {
        for (int col = 0; col < keyboardButtons.get(row).size(); ++col) {
            keyboardButtons.get(row).get(col).draw();
        }
    }

    // draw key labels
    for (int row = 0; row < keyTextLabels.size(); ++row) {
        for (int col = 0; col < keyTextLabels.get(row).size(); ++col) {
            keyTextLabels.get(row).get(col).draw();
        }
    }
}

void mouseReleased() {
    if (startTime==0) return;

    for (ArrayList<Button> btnRow : keyboardButtons)
        for (Button btn : btnRow)
            btn.tryOnClick();

    if (nextButtonX <= mouseX && mouseX <= nextButtonX + nextButtonWidth
        && nextButtonY <= mouseY && mouseY <= nextButtonY + nextButtonHeight) {
            nextTrial();
    }
}


void nextTrial()
{
    if (currTrialNum >= totalTrialNum) //check to see if experiment is done
        return; //if so, just return

    if (startTime!=0 && finishTime==0) //in the middle of trials
    {
        System.out.println("==================");
        System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
        System.out.println("Target phrase: " + currentPhrase); //output
        System.out.println("Phrase length: " + currentPhrase.length()); //output
        System.out.println("User typed: " + currentTyped); //output
        System.out.println("User typed length: " + currentTyped.length()); //output
        System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
        System.out.println("Time taken on this trial: " + (millis()-lastTime)); //output
        System.out.println("Time taken since beginning: " + (millis()-startTime)); //output
        System.out.println("==================");
        lettersExpectedTotal+=currentPhrase.trim().length();
        lettersEnteredTotal+=currentTyped.trim().length();
        errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
    }

    //probably shouldn't need to modify any of this output / penalty code.
    if (currTrialNum == totalTrialNum-1) //check to see if experiment just finished
    {
        finishTime = millis();
        System.out.println("==================");
        System.out.println("Trials complete!"); //output
        System.out.println("Total time taken: " + (finishTime - startTime)); //output
        System.out.println("Total letters entered: " + lettersEnteredTotal); //output
        System.out.println("Total letters expected: " + lettersExpectedTotal); //output
        System.out.println("Total errors entered: " + errorsTotal); //output

        float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
        float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
        float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
        
        System.out.println("Raw WPM: " + wpm); //output
        System.out.println("Freebie errors: " + freebieErrors); //output
        System.out.println("Penalty: " + penalty);
        System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
        System.out.println("==================");

        currTrialNum++; //increment by one so this mesage only appears once when all trials are done
        return;
    }

    if (startTime==0) //first trial starting now
    {
        System.out.println("Trials beginning! Starting timer..."); //output we're done
        startTime = millis(); //start the timer!
    } 
    else
        currTrialNum++; //increment trial number

    lastTime = millis(); //record the time of when this trial ended
    currentTyped = ""; //clear what is currently typed preparing for next trial
    currentPhrase = phrases[currTrialNum]; // load the next phrase!
    triggerIntellisense();
    //currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}


void drawWatch()
{
    float watchscale = DPIofYourDeviceScreen/138.0;
    pushMatrix();
    translate(width/2, height/2);
    scale(watchscale);
    imageMode(CENTER);
    image(watch, 0, 0);
    popMatrix();
}

void triggerIntellisense() {
    ArrayList<String> suggestions = intellisense.getSuggestedWords(currentTyped);
    System.out.println(currentTyped + " -> " + suggestions.toString());
    int suggestionIndex = 0;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < keyTextLabels.get(i).size(); ++j) {
            if (suggestionIndex < suggestions.size()) {
                keyTextLabels.get(i).get(j).strs = new String[] { suggestions.get(suggestionIndex) };
                suggestionIndex++;
            }
            else 
                keyTextLabels.get(i).get(j).strs = new String[] { "" };
        }
    }
}

//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
    int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

    for (int i = 0; i <= phrase1.length(); i++)
        distance[i][0] = i;
    for (int j = 1; j <= phrase2.length(); j++)
        distance[0][j] = j;

    for (int i = 1; i <= phrase1.length(); i++)
        for (int j = 1; j <= phrase2.length(); j++)
            distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

    return distance[phrase1.length()][phrase2.length()];
}

public interface ButtonOnClickHandler {
    void call();
}

class Button {
    float x;
    float y;
    float width; 
    float height;
    ButtonOnClickHandler onClick;

    public Button(float x, float y, float width, float height, ButtonOnClickHandler onClick) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.onClick = onClick;
    }

    public void tryOnClick() {
        if (x <= mouseX && mouseX <= x + width && y <= mouseY && mouseY <= y + height)
            this.onClick.call();
    }

    public void draw() {
        fill(255, 255, 255);
        stroke(128);
        rect(x, y, width, height);
    }
}

class HighlightedTextLabel {
    public String[] strs;
    float x;
    float y;
    float padding;
    int highlightedIndex = -1;

    public HighlightedTextLabel(float x, float y, float padding, String[] strs) {
        this.x = x;
        this.y = y;
        this.padding = padding;
        this.strs = strs;
    }

    public void draw() {
        textAlign(LEFT); 
        textFont(fontSmall);
        float currX = x;
        for (int i = 0; i < strs.length; ++i) {
            fill(0, 0, 0);
            if (i == highlightedIndex)
                fill(255, 0, 0);
            text(strs[i], currX, y);
            currX += padding + strs[i].length() * 4;
        }
    }

    public void unhighlight() { highlightedIndex = -1; }
    public void highlight(int index) { highlightedIndex = index; }
}

class Intellisense {
    ArrayList<ArrayList<String>> dataset = new ArrayList<>();

    // uses a 2 gram word model, P(X | prev word and prev prev word)
    // maps (whitespace trimed prev word and prev prev word) to 
    // (a map mapping (word) to (frequency))
    // note key should be of the form "" or "prevword" or "prevword prevprevword"
    // the first two forms are in case of not enough words
    HashMap<String, HashMap<String, Integer>> model = new HashMap<String, HashMap<String, Integer>>();

    // maps (whitespace trimed prev word and prev prev word) to a list of words x sorted by P(x | prev word and prev prev word)
    HashMap<String, ArrayList<String>> inference = new HashMap<String, ArrayList<String>>();

    HashMap<String, Integer> freqModel = new HashMap<String, Integer>();

    ArrayList<String> freqInference = new ArrayList<String>();

    public Intellisense(String[] sentences) {
        // build dataset
        for (int i = 0; i < sentences.length; ++i) {
            ArrayList<String> currRow = new ArrayList<>();
            String[] words = sentences[i].trim().split("\\s+");
            for (int j = 0; j < words.length; ++j) {
                currRow.add(words[j]);
            }
            dataset.add(currRow);
        }

        // build model and freqModel
        for (int i = 0; i < dataset.size(); ++i) {
            for (int j = 0; j < dataset.get(i).size(); ++j) {
                // model
                String key = getLastTwoWords(dataset.get(i), j);
                if (!model.containsKey(key)) {
                    model.put(key, new HashMap<String, Integer>());
                }
                String second_key = dataset.get(i).get(j);
                HashMap<String, Integer> mp = model.get(key);
                mp.put(second_key, mp.getOrDefault(second_key, 0) + 1);

                // freqModel
                freqModel.put(second_key, freqModel.getOrDefault(second_key, 0) + 1);
            }
        }
        
        // construct inference 
        for (HashMap.Entry<String, HashMap<String, Integer>> entry : model.entrySet()) {
            String key = entry.getKey();
            HashMap<String, Integer> mp = entry.getValue();

            ArrayList<HashMap.Entry<String, Integer>> rawList = new ArrayList<HashMap.Entry<String, Integer>>();
            for (HashMap.Entry<String, Integer> wordEntry : mp.entrySet())
                rawList.add(wordEntry);
            Collections.sort(rawList, Collections.reverseOrder(HashMap.Entry.comparingByValue()));

            ArrayList<String> list = new ArrayList<String>();
            for (HashMap.Entry<String, Integer> wordEntry : rawList) 
                list.add(wordEntry.getKey());

            inference.put(key, list);
        }

        // construct freqInference
        ArrayList<HashMap.Entry<String, Integer>> rawList = new ArrayList<HashMap.Entry<String, Integer>>();
        for (HashMap.Entry<String, Integer> entry : freqModel.entrySet())
            rawList.add(entry);
        Collections.sort(rawList, Collections.reverseOrder(HashMap.Entry.comparingByValue()));
        for (HashMap.Entry<String, Integer> entry : rawList)
            freqInference.add(entry.getKey());

        System.out.println("--------------- BEGIN SANITY TESTS (DEBUG) ---------------");
        System.out.println("---1  " + getSuggestedWords("").toString());
        System.out.println("---2  " + getSuggestedWords("t").toString());
        System.out.println("---3  " + getSuggestedWords("s").toString());
        System.out.println("---4  " + getSuggestedWords("the").toString());
        System.out.println("---5  " + getSuggestedWords("the ").toString());
        System.out.println("---6  " + getSuggestedWords("having is").toString());
        System.out.println("---7  " + getSuggestedWords("are having ").toString());
        System.out.println("---8  " + getSuggestedWords("jkafekjfk").toString());
        System.out.println("---9  " + getSuggestedWords("jkafekjfk ").toString());
        System.out.println("--------------- END SANITY TESTS (DEBUG) ---------------");
    }

    public ArrayList<String> getSuggestedWords(String sentence) {
        int numSuggested = 6;
        ArrayList<String> answer = new ArrayList<String>();

        ArrayList<String> words = new ArrayList<String>();
        Collections.addAll(words, sentence.trim().split("\\s+"));

        String prefix;
        int curr_index;
        if (sentence.length() == 0 || sentence.substring(sentence.length() - 1).equals(" ")) {
            // trying to get suggestion of a new word
            prefix = "";
            curr_index = words.size();
        } else {
            // trying to get suggestion of a partial word
            prefix = words.size() > 0 ? words.get(words.size() - 1) : "";
            curr_index = words.size() - 1;
        }

        String key = getLastTwoWords(sentence.trim(), curr_index);
        // System.out.println(String.format("getSuggestedWords key %s, prefix %s, curr_index %d, words %s", key, prefix, curr_index, words.toString()));
        int i = 0;
        if (inference.containsKey(key)) {
            while (i < min(numSuggested, inference.get(key).size())) {
                if (inference.get(key).get(i).startsWith(prefix))
                    answer.add(inference.get(key).get(i));
                ++i;
            }
        }
        i = answer.size();
        for (int j = 0; i < numSuggested && j < freqInference.size(); ++j) {
            if (freqInference.get(j).startsWith(prefix)) {
                answer.add(freqInference.get(j));
                ++i;
            }
        }
        return answer;
    }

    private String getLastTwoWords(String s, int curr_index) {
        ArrayList<String> words = new ArrayList<String>();
        Collections.addAll(words, s.trim().split("\\s+"));
        return getLastTwoWords(words, curr_index);
    }

    private String getLastTwoWords(ArrayList<String> s, int curr_index) {
        assert curr_index <= s.size() && 0 <= curr_index;
        if (curr_index == 0 || s.size() == 0)
            return "";
        if (curr_index == 1 || s.size() == 1)
            return s.get(0).trim();
        return s.get(curr_index - 1).trim() + " " + s.get(curr_index - 2).trim();
    }
}